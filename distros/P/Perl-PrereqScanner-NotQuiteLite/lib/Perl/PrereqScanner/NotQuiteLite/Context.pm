package Perl::PrereqScanner::NotQuiteLite::Context;

use strict;
use warnings;
use CPAN::Meta::Requirements;
use Regexp::Trie;
use Perl::PrereqScanner::NotQuiteLite::Util;

my %defined_keywords = _keywords();

my %default_op_keywords = map {$_ => 1} qw(
  x eq ne and or xor cmp ge gt le lt not
);

my %default_conditional_keywords = map {$_ => 1} qw(
  if elsif unless else
);

my %default_expects_expr_block = map {$_ => 1} qw(
  if elsif unless given when
  for foreach while until
);

my %default_expects_block_list = map {$_ => 1} qw(
  map grep sort
);

my %default_expects_fh_list = map {$_ => 1} qw(
  print printf say
);

my %default_expects_fh_or_block_list = (
  %default_expects_block_list,
  %default_expects_fh_list,
);

my %default_expects_block = map {$_ => 1} qw(
  else default
  eval sub do while until continue
  BEGIN END INIT CHECK
  if elsif unless given when
  for foreach while until
  map grep sort
);

my %default_expects_word = map {$_ => 1} qw(
  use require no sub
);

my %enables_utf8 = map {$_ => 1} qw(
  utf8
  Mojo::Base
  Mojo::Base::Che
);

my $default_g_re_prototype = qr{\G(\([^\)]*?\))};

sub new {
  my ($class, %args) = @_;

  my %context = (
    requires => CPAN::Meta::Requirements->new,
    noes => CPAN::Meta::Requirements->new,
    file => $args{file},
    verbose => $args{verbose},
    optional => $args{optional},
    stash => {},
  );

  if ($args{suggests} or $args{recommends}) {
    $context{recommends} = CPAN::Meta::Requirements->new;
  }
  if ($args{suggests}) {
    $context{suggests} = CPAN::Meta::Requirements->new;
  }
  if ($args{perl_minimum_version}) {
    $context{perl} = CPAN::Meta::Requirements->new;
  }
  for my $type (qw/use no method keyword sub/) {
    if (exists $args{_}{$type}) {
      for my $key (keys %{$args{_}{$type}}) {
        $context{$type}{$key} = [@{$args{_}{$type}{$key}}];
      }
    }
  }

  bless \%context, $class;
}

sub stash { shift->{stash} }

sub register_keyword_parser {
  my ($self, $keyword, $parser_info) = @_;
  $self->{keyword}{$keyword} = $parser_info;
  $self->{defined_keywords}{$keyword} = 0;
}

sub remove_keyword_parser {
  my ($self, $keyword) = @_;
  delete $self->{keyword}{$keyword};
  delete $self->{keyword} if !%{$self->{keyword}};
  delete $self->{defined_keywords}{$keyword};
}

sub register_method_parser {
  my ($self, $method, $parser_info) = @_;
  $self->{method}{$method} = $parser_info;
}

*register_keyword = \&register_keyword_parser;
*remove_keyword = \&remove_keyword_parser;
*register_method = \&register_method_parser;

sub register_sub_parser {
  my ($self, $keyword, $parser_info) = @_;
  $self->{sub}{$keyword} = $parser_info;
  $self->{defined_keywords}{$keyword} = 0;
}

sub requires { shift->{requires} }
sub recommends { shift->_optional('recommends') }
sub suggests { shift->_optional('suggests') }
sub noes { shift->{noes} }

sub _optional {
  my ($self, $key) = @_;
  my $optional = $self->{$key} or return;

  # no need to recommend/suggest what are listed as requires
  if (my $requires = $self->{requires}) {
    my $hash = $optional->as_string_hash;
    for my $module (keys %$hash) {
      if (defined $requires->requirements_for_module($module) and
          $requires->accepts_module($module, $hash->{$module})
      ) {
        $optional->clear_requirement($module);
      }
    }
  }
  $optional;
}

sub add {
  my $self = shift;
  if ($self->{optional}) {
    $self->_add('suggests', @_);
  } else {
    $self->_add('requires', @_);
  }
}

sub add_recommendation {
  shift->_add('recommends', @_);
}

sub add_suggestion {
  shift->_add('suggests', @_);
}

sub add_conditional {
  shift->_add('conditional', @_);
}

sub add_no {
  shift->_add('noes', @_);
}

sub add_perl {
  my ($self, $perl, $reason) = @_;
  return unless $self->{perl};
  $self->_add('perl', 'perl', $perl);
  $self->{perl_minimum_version}{$reason} = $perl;
}

sub _add {
  my ($self, $type, $module, $version) = @_;
  return unless is_module_name($module);

  my $CMR = $self->_object($type) or return;
  $version = 0 unless defined $version;
  if ($self->{verbose}) {
    if (!defined $CMR->requirements_for_module($module)) {
      print STDERR "  found $module $version ($type)\n";
    }
  }
  $CMR->add_minimum($module, "$version");
}

sub has_added {
  shift->_has_added('requires', @_);
}

sub has_added_recommendation {
  shift->_has_added('recommends', @_);
}

sub has_added_suggestion {
  shift->_has_added('suggests', @_);
}

sub has_added_conditional {
  shift->_has_added('conditional', @_);
}

sub has_added_no {
  shift->_has_added('no', @_);
}

sub _has_added {
  my ($self, $type, $module) = @_;
  return unless is_module_name($module);

  my $CMR = $self->_object($type) or return;
  defined $CMR->requirements_for_module($module) ? 1 : 0;
}

sub _object {
  my ($self, $key) = @_;
  if ($self->{eval}) {
    $key = 'suggests';
  } elsif ($self->{force_cond}) {
    $key = 'recommends';
  } elsif ($key && $key eq 'conditional') {
    if ($self->{cond}) {
      $key = 'recommends';
    } elsif (grep {$_->[0] eq '{' and $_->[2] ne 'BEGIN'} @{$self->{stack} || []}) {
      $key = 'recommends';
    } else {
      $key = 'requires';
    }
  } elsif (!$key) {
    $key = 'requires';
  }
  $self->{$key} or return;
}

sub has_callbacks {
  my ($self, $type) = @_;
  exists $self->{$type};
}

sub has_callback_for {
  my ($self, $type, $name) = @_;
  exists $self->{$type}{$name};
}

sub run_callback_for {
  my ($self, $type, $name, @args) = @_;
  return unless $self->_object;
  my ($parser, $method, @cb_args) = @{$self->{$type}{$name}};
  $parser->$method($self, @cb_args, @args);
}

sub prototype_re {
  my $self = shift;
  if (@_) {
    $self->{prototype_re} = shift;
  }
  return $default_g_re_prototype unless exists $self->{prototype_re};
  $self->{prototype_re};
}

sub quotelike_re {
  my $self = shift;
  return qr/qq?/ unless exists $self->{quotelike_re};
  $self->{quotelike_re};
}

sub register_quotelike_keywords {
  my ($self, @keywords) = @_;
  push @{$self->{quotelike}}, @keywords;
  $self->{defined_keywords}{$_} = 0 for @keywords;

  my $trie = Regexp::Trie->new;
  $trie->add($_) for 'q', 'qq', @{$self->{quotelike} || []};
  $self->{quotelike_re} = $trie->regexp;
}

sub token_expects_block_list {
  my ($self, $token) = @_;
  return 1 if exists $default_expects_block_list{$token};
  return 0 if !exists $self->{expects_block_list};
  return 1 if exists $self->{expects_block_list}{$token};
  return 0;
}

sub token_expects_fh_list {
  my ($self, $token) = @_;
  return 1 if exists $default_expects_fh_list{$token};
  return 0 if !exists $self->{expects_fh_list};
  return 1 if exists $self->{expects_fh_list}{$token};
  return 0;
}

sub token_expects_fh_or_block_list {
  my ($self, $token) = @_;
  return 1 if exists $default_expects_fh_or_block_list{$token};
  return 0 if !exists $self->{expects_fh_or_block_list};
  return 1 if exists $self->{expects_fh_or_block_list}{$token};
  return 0;
}

sub token_expects_expr_block {
  my ($self, $token) = @_;
  return 1 if exists $default_expects_expr_block{$token};
  return 0 if !exists $self->{expects_expr_block};
  return 1 if exists $self->{expects_expr_block}{$token};
  return 0;
}

sub token_expects_block {
  my ($self, $token) = @_;
  return 1 if exists $default_expects_block{$token};
  return 0 if !exists $self->{expects_block};
  return 1 if exists $self->{expects_block}{$token};
  return 0;
}

sub token_expects_word {
  my ($self, $token) = @_;
  return 1 if exists $default_expects_word{$token};
  return 0 if !exists $self->{expects_word};
  return 1 if exists $self->{expects_word}{$token};
  return 0;
}

sub token_is_conditional {
  my ($self, $token) = @_;
  return 1 if exists $default_conditional_keywords{$token};
  return 0 if !exists $self->{is_conditional_keyword};
  return 1 if exists $self->{is_conditional_keyword}{$token};
  return 0;
}

sub token_is_keyword {
  my ($self, $token) = @_;
  return 1 if exists $defined_keywords{$token};
  return 0 if !exists $self->{defined_keywords};
  return 1 if exists $self->{defined_keywords}{$token};
  return 0;
}

sub token_is_op_keyword {
  my ($self, $token) = @_;
  return 1 if exists $default_op_keywords{$token};
  return 0 if !exists $self->{defined_op_keywords};
  return 1 if exists $self->{defined_op_keywords}{$token};
  return 0;
}

sub register_keywords {
  my ($self, @keywords) = @_;
  for my $keyword (@keywords) {
    $self->{defined_keywords}{$keyword} = 0;
  }
}

sub register_op_keywords {
  my ($self, @keywords) = @_;
  for my $keyword (@keywords) {
    $self->{defined_op_keywords}{$keyword} = 0;
  }
}

sub remove_keywords {
  my ($self, @keywords) = @_;
  for my $keyword (@keywords) {
    delete $self->{defined_keywords}{$keyword} if exists $self->{defined_keywords}{$keyword} and !$self->{defined_keywords}{$keyword};
  }
}

sub register_sub_keywords {
  my ($self, @keywords) = @_;
  for my $keyword (@keywords) {
    $self->{defines_sub}{$keyword} = 1;
    $self->{expects_block}{$keyword} = 1;
    $self->{expects_word}{$keyword} = 1;
    $self->{defined_keywords}{$keyword} = 0;
  }
}

sub token_defines_sub {
  my ($self, $token) = @_;
  return 1 if $token eq 'sub';
  return 0 if !exists $self->{defines_sub};
  return 1 if exists $self->{defines_sub}{$token};
  return 0;
}

sub enables_utf8 {
  my ($self, $module) = @_;
  exists $enables_utf8{$module} ? 1 : 0;
}

sub add_package {
  my ($self, $package) = @_;
  $self->{packages}{$package} = 1;
}

sub packages {
  my $self = shift;
  keys %{$self->{packages} || {}};
}

sub remove_inner_packages_from_requirements {
  my $self = shift;
  for my $package ($self->packages) {
    for my $rel (qw/requires recommends suggests noes/) {
      next unless $self->{$rel};
      $self->{$rel}->clear_requirement($package);
    }
  }
}

sub merge_perl {
  my $self = shift;
  return unless $self->{perl};

  my $perl = $self->{requires}->requirements_for_module('perl');
  if ($self->{perl}->accepts_module('perl', $perl)) {
    delete $self->{perl_minimum_version};
  } else {
    $self->add(perl => $self->{perl}->requirements_for_module('perl'));
  }
}

sub _keywords {
    my $i = 1;
    map {$_ => $i++} qw(
        __CLASS__
        __DATA__
        __END__
        __FILE__
        __LINE__
        __PACKAGE__
        __SUB__
        ADJUST
        AUTOLOAD
        BEGIN
        CHECK
        DESTROY
        END
        INIT
        UNITCHECK
        abs
        accept
        alarm
        all
        and
        any
        atan2
        bind
        binmode
        bless
        break
        caller
        catch
        chdir
        chmod
        chomp
        chop
        chown
        chr
        chroot
        class
        close
        closedir
        cmp
        connect
        continue
        cos
        crypt
        dbmclose
        dbmopen
        default
        defer
        defined
        delete
        die
        do
        dump
        each
        else
        elsif
        endgrent
        endhostent
        endnetent
        endprotoent
        endpwent
        endservent
        eof
        eq
        eval
        evalbytes
        exec
        exists
        exit
        exp
        fc
        fcntl
        field
        fileno
        finally
        flock
        for
        foreach
        fork
        format
        formline
        ge
        getc
        getgrent
        getgrgid
        getgrnam
        gethostbyaddr
        gethostbyname
        gethostent
        getlogin
        getnetbyaddr
        getnetbyname
        getnetent
        getpeername
        getpgrp
        getppid
        getpriority
        getprotobyname
        getprotobynumber
        getprotoent
        getpwent
        getpwnam
        getpwuid
        getservbyname
        getservbyport
        getservent
        getsockname
        getsockopt
        given
        glob
        gmtime
        goto
        grep
        gt
        hex
        if
        index
        int
        ioctl
        isa
        join
        keys
        kill
        last
        lc
        lcfirst
        le
        length
        link
        listen
        local
        localtime
        lock
        log
        lstat
        lt
        m
        map
        method
        mkdir
        msgctl
        msgget
        msgrcv
        msgsnd
        my
        ne
        next
        no
        not
        oct
        open
        opendir
        or
        ord
        our
        pack
        package
        pipe
        pop
        pos
        print
        printf
        prototype
        push
        q
        qq
        qr
        quotemeta
        qw
        qx
        rand
        read
        readdir
        readline
        readlink
        readpipe
        recv
        redo
        ref
        rename
        require
        reset
        return
        reverse
        rewinddir
        rindex
        rmdir
        s
        say
        scalar
        seek
        seekdir
        select
        semctl
        semget
        semop
        send
        setgrent
        sethostent
        setnetent
        setpgrp
        setpriority
        setprotoent
        setpwent
        setservent
        setsockopt
        shift
        shmctl
        shmget
        shmread
        shmwrite
        shutdown
        sin
        sleep
        socket
        socketpair
        sort
        splice
        split
        sprintf
        sqrt
        srand
        stat
        state
        study
        sub
        substr
        symlink
        syscall
        sysopen
        sysread
        sysseek
        system
        syswrite
        tell
        telldir
        tie
        tied
        time
        times
        tr
        truncate
        try
        uc
        ucfirst
        umask
        undef
        unless
        unlink
        unpack
        unshift
        untie
        until
        use
        utime
        values
        vec
        wait
        waitpid
        wantarray
        warn
        when
        while
        write
        x
        xor
        y
    );
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Context

=head1 DESCRIPTION

This is typically used to keep callbacks, an eval state, and
found prerequisites for a processing file.

=head1 METHODS

=head2 add

  $c->add($module);
  $c->add($module => $minimum_version);

adds a module with/without a minimum version as a requirement
or a suggestion, depending on the eval state. You can add a module
with different versions as many times as you wish. The actual
minimum version for the module is calculated inside
(by L<CPAN::Meta::Requirements>).

=head2 register_keyword_parser, remove_keyword_parser, register_method_parser, register_sub_parser

  $c->register_keyword_parser(
    'func_name',
    [$parser_class, 'parser_for_the_func', $used_module],
  );
  $c->remove_keyword_parser('func_name');

  $c->register_method_parser(
    'method_name',
    [$parser_class, 'parser_for_the_method', $used_module],
  );

If you find a module that can export a loader function is actually
C<use>d (such as L<Moose> that can export an C<extends> function
that will load a module internally), you might also register the
loader function as a custom keyword dynamically so that the scanner
can also run a callback for the function to parse its argument
tokens.

You can also remove the keyword when you find the module is C<no>ed
(and when the module supports C<unimport>).

You can also register a method callback on the fly (but you can't
remove it).

If you always want to check some functions/methods when you load a
plugin, just register them using a C<register> method in the plugin.

=head2 requires

returns a CPAN::Meta::Requirements object for requirements.

=head2 suggests

returns a CPAN::Meta::Requirements object for suggestions
(requirements in C<eval>s), or undef when it is not expected to
parse tokens in C<eval>.

=head1 METHODS MOSTLY FOR INTERNAL USE

=head2 new

creates an instance. You usually don't need to call this because
it's automatically created in the scanner.

=head2 has_callbacks, has_callback_for, run_callback_for

  next unless $c->has_callbacks('use');
  next unless $c->has_callbacks_for('use', 'base');
  $c->run_callbacks_for('use', 'base', $tokens);

C<has_callbacks> returns true if a callback for C<use>, C<no>,
C<keyword>, or C<method> is registered. C<has_callbacks_for>
returns true if a callback for the module/keyword/method is
registered. C<run_callbacks_for> is to run the callback.

=head2 has_added

returns true if a module has already been added as a requirement
or a suggestion. Only useful for the ::UniversalVersion plugin.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
