use strict;
use warnings;

package Net::OAuth2::Scheme::Option::Builder;
BEGIN {
  $Net::OAuth2::Scheme::Option::Builder::VERSION = '0.03';
}
# ABSTRACT: poor man's mixin/role closure builder

use Net::OAuth2::Scheme::Option::Defines qw(All_Classes);


# use machinery from Net::OAuth2::TokenType::Scheme::Defines
# to gather all default values and group definitions
sub _all_defaults {
    my $class = shift;
    no strict 'refs';
    map {%{"${_}::Default"}} All_Classes($class);
}

sub _all_groups {
    my $class = shift;
    no strict 'refs';
    map {%{"${_}::Group"}} All_Classes($class);
}

# group finder, in case we need it
our %find_group;
sub _find_group {
    my $class = shift;
    unless ($find_group{$class}) {
        my %group = $class->_all_groups;
        my %fg = ();
        for my $g (keys %group) {
            $fg{$_} = $g for @{$group{$g}->{keys}};
        }
        $find_group{$class} = \%fg;
    }
    return $find_group{$class};
}

# if we need to see whether we are leaving behind
# any closures with links to self
our $Visible_Destroy = 0;
sub DESTROY {
    print STDERR "Boom!\n" if $Visible_Destroy;
}


use fields qw(value alias default pkg export);

# alias:   name -> name2 (where named option actually lives)
# default: name -> default value to use if value not specified
# pkg:     name -> [pkg, args...] to invoke if value not specified
# value:   name -> value (value for named option or undef)
# export:  list of exported names

sub new {
    my $class = shift;
    my %opts = @_;
    $class = ref($class) if ref($class);
    my __PACKAGE__ $self = fields::new($class);

    my %group = $class->_all_groups;
    for my $i (values %group) {
        if (defined $i->{default}) {
            $self->{pkg}->{$_} = $i->{default}
              for @{$i->{keys}};
        }
    }
    for my $o (keys %opts) {
        if (my $i = $group{$o}) {
            my $impl = $opts{$o};
            my @ispec = ref($impl) ? @{$impl} : ($impl);
            $ispec[0] = "pkg_${o}_$ispec[0]";
            $self->{pkg}->{$_} = \@ispec
              for @{$i->{keys}};
        }
        else {
            $self->{value}->{$o} = $opts{$o};
        }
    }

    $self->{default} =
      $self->{value}->{defaults_all}
        ||
      { _all_defaults(ref($self)),
        %{$self->{value}->{defaults} || {}},
      };
    return $self;
}

# define our own croak so that there are reasonable error messages when options get set incorrectly
our @load = ();
our $Show_Uses_Stack = 1; #for now

sub croak {
    my __PACKAGE__ $self = shift;
    my $msg = shift;
    my $c = 0;
    for my $key (@load) {
        my $from = ref($self)->_find_group->{$key} || '';
        if ($from) {
            my $pkg_foo = $self->{pkg}->{$key} ? $self->{pkg}->{$key}->[0] : '?';
            $from = " (group $from ($pkg_foo))";
        }
        ++$c;
        while (defined(caller($c)) && (caller($c))[3] !~ '::uses$') { ++$c; }
        while ((caller($c))[0] eq __PACKAGE__) { ++$c; }
        if ($Show_Uses_Stack) {
            my ($file,$line) = (caller($c))[1,2];
            print STDERR "... option '$key'$from needed at $file, line $line'\n";
        }
    }
    {
        no strict 'refs';
        # make Carp trust everyone between here and first caller to uses()
        # which is usually going to be Scheme->new().
        push @{(caller($_))[0] . '::CARP_NOT'}, __PACKAGE__
          for (0..$c);
    }
    Carp::croak($msg);
}

# actual('key')
# where to lookup pkg,default,value for 'key'
sub actual {
    my __PACKAGE__ $self = shift;
    my ($key) = @_;
    while (defined(my $nkey = $self->{alias}->{$key})) {
        $key = $nkey;
    }
    return $key;
}

# alias('key','key2')
# causes options 'key' and 'key2' to become synonyms
sub make_alias {
    my __PACKAGE__ $self = shift;
    my ($okey, $okey2) = @_;
    my ( $key,  $key2) = map {$self->actual($_)} @_;

    # only options that have not been claimed by groups
    # can have {alias} entries; so make sure $key is
    # the one that is not in a group.
    (    $key, $key2, $okey, $okey2)
      = ($key2, $key, $okey2, $okey)
        if $self->{pkg}->{$key};

    # if both $key and $key2 are in groups, we die,
    # because otherwise, there will be ambiguity about
    # which pkg_ routine is invoked to initialize them
    Carp::croak("cannot alias group members to each other: '$okey'"
                .($okey ne $key ? " ('$key')" : "")
                ." <-> '$okey2'"
                .($okey2 ne $key2 ? " ('$key2')" :""))
        if $self->{pkg}->{$key};

    # if there is a value, make sure it lives on $key2
    if (defined($self->{value}->{$key2})) {
        $self->croak("settings of options '$key' and '$key2' conflict")
          if (defined($self->{value}->{$key})
              && $self->{value}->{$key} ne $self->{value}->{$key2});
    }
    elsif (defined($self->{value}->{$key})) {
        $self->{value}->{$key2} = $self->{value}->{$key};
    }

    # if there is a default value, make sure it lives on $key2
    if (defined($self->{default}->{$key2})) {
        # make conflicting defaults disappear
        delete $self->{default}->{$key2}
          if (defined($self->{default}->{$key})
              && $self->{default}->{$key} ne $self->{default}->{$key2});
    }
    elsif (defined($self->{default}->{$key})) {
        $self->{default}->{$key2} = $self->{default}->{$key};
    }
    # remove stuff that does not matter anymore
    delete $self->{default}->{$key};
    delete $self->{value}->{$key};

    # we can point $key to $key2 (finally)
    $self->{alias}->{$key} = $key2;
}


# installed('key')
# value for 'key' or undef
sub installed {
    my __PACKAGE__ $self = shift;
    my ($key, $default) = @_;

    return $self->{value}->{$self->actual($key)};
}


# uses(key => [,default_value])
# value for 'key'; if not defined yet
# either use default_value, {default}->{key}, install package for it, or die
sub uses {
    my __PACKAGE__ $self = shift;
    my ($okey, $default) = @_;
    my $key = $self->actual($okey);
    local @load = ($okey, @load);

    unless (exists($self->{value}->{$key})) {
        if (defined $default
            || defined($default = $self->{default}->{$key})) {
            $self->install($key, $default);
        }
        elsif (my ($pkg,@kvs) = @{$self->{pkg}->{$key} || []}) {
            ($pkg,@kvs) = @$pkg if ref($pkg);
            $self->$pkg(@kvs);
            Carp::croak("package failed to define value:  $pkg -> $key")
                unless defined($self->{value}->{$key});
        }
    }
    my $value = $self->{value}->{$key};
    unless (defined($value)) {
        my $g = ref($self)->_find_group->{$key};
        $self->croak("a setting for '".($g || $key)."' is needed");
    }
    return $value;
}

# ensure(key => $value, $msg)
# == uses(key => $value) and die with $msg if value is not $value
sub ensure {
    my __PACKAGE__ $self = shift;
    my ($key, $value, $msg) = @_;
    $self->uses($key, $value) eq $value
      or $self->croak($msg || "option '$key' must be '$value' here.");
    return $value;
}

# uses_all(qw(key1 key2 ...))
# == (uses('key1'), uses('key2'),...)
sub uses_all {
    my __PACKAGE__ $self = shift;
    return map {$self->uses($_)} @_;
}

sub parameter_prefix {
    my __PACKAGE__ $self = shift;
    my $prefix = shift;
    if (@_ && $_[0] eq '_default') {
        shift;
        # discard default parameter name if not needed
        shift if @_ % 2;
    }
    my (%h) = @_;
    $self->ensure("${prefix}$_",$h{$_})
      for (keys %h);
}

# install(key => $value) sets option 'key' to $value
sub install {
    my __PACKAGE__ $self = shift;
    my ($okey, $value) = @_;
    my $key = $self->actual($okey);

    Carp::croak("tried to install undef?:  $okey")
        unless defined $value;
    Carp::croak("multiple definitions?:  $okey")
        if defined $self->{value}->{$key};

    $self->{value}->{$key} = $value;
}

# export(keys...) == uses_all(keys ...)
# marking all keys as being exported.
sub export {
    my __PACKAGE__ $self = shift;
    my @r = $self->uses_all(@_);
    $self->{export}->{$_}++ for (@_);
    return @r;
}

sub all_exports {
    my __PACKAGE__ $self = shift;
    return keys %{$self->{export}};
}


    #   new( defaults => { additional defaults... } ...)
    #     if you want to keep all of the various default values set
    #     and only make minor changes
    #   new( defaults_all => { defaults ...}
    #     if you want to entirely replace all default values;
    #     in which case this function never gets called
    #     since defaults_all is already set;
    #     Kids, don't try this at home...

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Option::Builder - poor man's mixin/role closure builder

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use parent Net::OAuth2::TokenType::Option::Builder;

  Define_Group gearshift => tenspeed,
    qw(gearshift_doshift gearshift_coast);

  sub pkg_gearshift_tenspeed {
    my $self = shift;
    my $count = $self->uses(gearcount);
    $self->install(gearshift_doshift => sub {
       ...
    }
    $self->install(gearshift_coast => sub {
       ...
    }
  }

  sub pkg_gearshift_sturmey_archer {
    ...
  }

=head1 DESCRIPTION

 buh.

=head1 METHODS

=over

=item B<install> (C<< name => $value >>)

Installs a value for option C<name>.

=item B<uses> (C<name>I<[, >C<$default>I<]>)

Gets the value for option C<name>.

If no value has yet been intalled,
installs a default value if one has been specified either
here (C<$default>) or elsewhere
(e.g., using the C<defaults> group or B<Define_value>)

Otherwise, C<name> must be part of some group,
so we see which implementation for that group
has been chosen and invoke it to set C<name>
(and whatever else) so that we can get a value.

=item B<export> C<'name'>

Does B<uses>(C<'name'>) then adds C<'name'>
to the list of exported options.

=item B<ensure> (C<< name => $value >>)

Does B<uses>(C<< name => $value >>)
then dies if option C<name> does not, in fact, have the value C<$value>.

=item B<uses_all> (C<<qw( name1 name2 ... )>>)

Equivalent to B<uses>(C<name1>), B<uses>(C<name2>), etc...,
returning the list of corresponding values.

=item B<uses_param>

=item B<uses_params>

=item B<croak> ($msg)

Like L<Carp::croak> but only for errors that are clearly the result of mistakes in option settings.

=back

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

