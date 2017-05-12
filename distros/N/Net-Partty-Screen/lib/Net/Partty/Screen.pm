package Net::Partty::Screen;

use strict;
use warnings;
use base 'Term::Screen';
our $VERSION = '0.01';

use Net::Partty;
use Term::Cap;

sub new {
    my($class, %opts) = @_;

    my $self = bless {
        %opts,
        IN   => '',
        KEYS => {},
        ECHO => 1,
    }, $class;

    unless ($self->{term}) {
        my $term = Term::Cap->Tgetent({
            TERM   => 'vt100',
            OSPEED => 9600,
        });
        $self->term($term);
    }
    $self->resize;
    $self->get_fn_keys;

    $self->{partty} = delete $opts{partty} || Net::Partty->new(%{ $opts{partty_conf} || {} }) unless $self->{sock};

    if ($self->{debug}) {
        eval { require Term::ReadKey; };
        if ($@) {
            require Carp;
            Carp::croak $@;
        }

        $self->at(0, 0);
        Term::ReadKey::ReadMode('raw', \*STDIN);
        $| = 1;
    }

    $self;
}

sub DESTROY {
    Term::ReadKey::ReadMode(0, \*STDIN) if shift->{debug};
}

sub sock { shift->{sock} }
sub partty { shift->{partty} }
sub connect {
    my $self = shift;
    $self->{partty}->connect(@_);
    $self->{sock} = $self->partty->sock;
    $self->sock->sb(chr(31), pack('nn', $self->{COLS}, $self->{ROWS}));
    $self->sock->blocking(0);
    $self->at(0, 0);
}

sub esc {
    my($self, $fmt, @args) = @_;
    $self->puts(sprintf "%s$fmt", chr(0x1b), @args);
}

# sub term {}
# sub rows {}
# sub cols {}

sub at {
    my($self, $rows, $cols) = @_;
    $rows = 0 if $rows < 0;
    $cols = 0 if $cols < 0;
    $rows = $self->{ROWS} - 1 if $rows >= $self->{ROWS};
    $cols = $self->{COLS} - 1 if $cols >= $self->{COLS};
    $self->esc('[%s;%sH', $rows + 1, $cols + 1);
    $self;
}

sub resize {
    my($self, $rows, $cols) = @_;
    $self->{ROWS} = $rows || 25;
    $self->{COLS} = $cols || 80;
    $self;
}

sub normal { shift->esc('[m') }
sub bold { shift->esc('[1m') }
sub reverse { shift->esc('[7m') }
sub clrscr { shift->esc('[2J')->at(0, 0) }
sub clreol { shift->esc('[0K') }
sub creos { shift->esc('[0J') }
sub il { shift->esc('[L') }
sub dl { shift->esc('[M') }

sub ic_exists { 0 }
sub ic { shift }
sub dc_exists { 0 }
sub dc { shift }

sub puts {
    my($self, $data) = @_;
    if ($self->{debug}) {
        print $data;
    } else {
        $self->sock->send($data);
        $self->partty->can_write(100);
    }
    $self;
}

sub getc {
    my $self = shift;
    return CORE::getc(STDIN) if $self->{debug};

    $self->partty->can_read(100);
    return $self->sock->getc;
}

sub getch {
    my $self           = shift;
    my $fn_flag        = 0;
    my $char           = $self->{IN} ? chop($self->{IN}) : $self->getc;
    my $partial_fn_str = $char;
    return unless $char;

    while (exists($self->{KEYS}{$partial_fn_str})) {
        $fn_flag = 1;
        if ($self->{KEYS}{$partial_fn_str}) {
            $char           = $self->{KEYS}{$partial_fn_str};
            $partial_fn_str = '';
            last;
        }
        $partial_fn_str .= $self->{IN} ? chop($self->{IN}) : $self->getc;
    }

    if ($fn_flag) {
        if ($partial_fn_str) {
            if ($partial_fn_str eq "\e\e") {
                $char = "\e";
            } else {
                $self->{IN} = CORE::reverse($partial_fn_str) . $self->{IN};
                $char = chop($self->{IN});
                $self->puts($char) if $self->{ECHO} && $char ne "\e";
            }
        }
    } elsif ($self->{ECHO} && $char ne "\e") {
        $self->puts($char);
    }
    $char;
}

# sub def_key {}

sub key_pressed {
    my($self, $wait) = @_;
    my $fds   = '';
    my $ready = 0;

    my $fno = $self->{debug} ? fileno(STDIN) : fileno($self->sock);
    $wait = 0 unless defined $wait;

    vec($fds, $fno, 1) = 1;
    eval {
        $ready = select($fds, undef, undef, $wait);
    };
    $ready;
}

# sub echo {}
# sub noecho {}

sub flush_input {
    my $self = shift;
    $self->{IN} = '';
    while ($self->key_pressed) { $self->getc }
    $self;
}


# sub stuff_input {}
# sub get_fn_keys {}

1;
__END__

=encoding utf8

=head1 NAME

Net::Partty::Screen - Term::Screen for Net::Partty

=head1 SYNOPSIS

  use Net::Partty::Screen;

   my $scr = net::Partty::Screen->new;
   $scr->connect(
       message           => 'message',
       session_name      => 'session_name',
       writable_password => 'writable_password',
       readonly_password => '',
   );
   $scr->clrscr();
   $scr->at(5,3);
   $scr->puts("this is some stuff");
   $scr->at(10,10)->bold()->puts("hi!")->normal();
      # you can concatenate many calls (not getch)
   $c = $scr->getch();      # doesn't need Enter key 
   ...
   if ($scr->key_pressed()) { print "ha you hit a key!"; }


=head1 DESCRIPTION

Net::Partty::Screen is Term::Screen interface for Partty.org

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<Term::Screen>, L<Net::Partty>, L<http://www.partty.org/>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Net-Partty-Screen/trunk Net-Partty-Screen

Net::Partty::Screen is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
