package Script::Carp;

use Carp ();
use strict;
use warnings;

our $IGNORE_EVAL = 0; # for test

my $_die = sub {};

*CORE::GLOBAL::die = sub {
  my ($package, $filename, $line) = caller;

  if (defined $_[0] and $_[0] =~/^Died /) {
    $_die->(@_)
  } elsif (defined $_[0] and $_[0] =~/ at $filename line $line\./)  {
    $_die->('Died ', @_);
  } else {
    $_die->('Died ', @_, " at $filename line $line.\n")
  }
};
$SIG{__DIE__} = sub { $_die->(@_) };

our $FLGS =
  {
   -file => sub {
     my ($args) = @_;
     my $file = shift @$args;
     Carp::croak("USAGE: use Script::Carp -file => 'file_name'") unless $file;
     return sub {
       my (@args) = @_;
       my ($package, $filename, $line) = caller(1);
       open my $out, ">", $file or die "cannot open file '$file'.";
       print $out @args;
       close $out;
     };
   },
   -stop => sub {
     return sub { print STDERR "Hit Enter to exit:"; <> };
   },
   -log => sub {
     my ($args) = @_;
     my $file = shift @$args;
     Carp::croak("USAGE: use Script::Carp -log => 'file_name'") unless $file;
     return sub {
       my @args = @_;
       open my $out, ">>", $file or die "cannot open file '$file'.";
       print $out scalar localtime, "\n";
       print $out @args;
       close $out;
     };
   },
   -clip => sub {
     eval "require Clipboard; Clipboard->import()";
     unless($@) {
       my ($args) = @_;
       return sub {
         eval {
           Clipboard->copy(join "", @_) if @_;
         };
         if ($@) {
           warn $@;
         }
       }
     } else {
       my $msg = "You need Clipboard module.";
       warn $msg;
       return sub {};
     } 
   },
   -beep => sub {
     local $@;
     eval "require Audio::Beep";
     unless ($@) {
       my ($args) = @_;
       $args->[0] ||= "c' d' e'";
       my $beep = $args->[0] =~/^-/ ? "c' d' e'" : shift @$args;
       return sub {
         Audio::Beep->new->play($beep);
       }
     } else {
       my $msg = "You need Audio::Beep module.";
       $msg .= ' you may need "modprobe pcspkr" and/or "xset b on"' if $^O =~/linux/i;
       warn $msg;
       return sub {};
     }
   },
   -ignore_eval => sub {
     # only for test
     $IGNORE_EVAL = 1;
     return sub { };
   },
  };

sub import {
  my ($self, @opt) = @_;

  my @subs;
  while (@opt) {
    my $flg = shift @opt;
    if (my $gen = $FLGS->{$flg}) {
      push @subs, $gen->(\@opt);
    }
  }
  no warnings;
  $_die = sub {
    my ($package, $filename, $line) = caller(1);
    my @args = @_;
    if (! $IGNORE_EVAL and defined $^S and $^S == 1) {
      CORE::die @args;
    } else {
      print STDERR @args, $IGNORE_EVAL ? '' : " at $filename line $line.\n";
      _auto_flush();
      for (@subs) {
        _auto_flush();
        $_->(@args);
      }
      exit 255 unless $IGNORE_EVAL;
    }
  };
}

sub _auto_flush {
  $| = 1;
  my $fh = select;
  select STDERR;
  $| = 1;
  select $fh;
}

*setup = \&import;

=head1 NAME

Script::Carp - provide some ways to leave messages when script died

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

use this with options.

  use Script::Carp -stop; # display error and wait STDIN
  use Script::Carp -file => "error.txt"; # write message to error.txt
  use Script::Carp -stop, -file => "error.txt"; # mixed the above
  use Script::Carp -log  => "error_log.txt"; # append message to error_log.txt
  use Script::Carp -beep => "c d e f g"; # beep
  use Script::Carp -clip; # message is copied to clipboard

use class method with options

  Script::Carp->setup(-stop);
  Script::Carp->setup(-file => "error.txt");
  Script::Carp->setup(-log => "error_log.txt");
  Script::Carp->setup(-stop, -file => "error.txt");
  Script::Carp->setup(-beep => "c d e f g");
  Script::Carp->setup(-clip);

=head1 DESCRIPTION

When you write script on MS Windows and run it and then it died,
prompt window is immediately clesed and you cannot see any messages.

For such case, this module is usefule.

When You use this module with some options or use setup method with some options,
you can check error message, easily.

=head1 OPTIONS

options can be used with use Script::Carp or class method setup method.

=head2 -stop

 use Script::Carp -stop;

or

 Script::Carp->setup(-stop);

When script died, display messages and wait STDIN.

=head2 -file => 'file_name'

 use Script::Carp -file => 'file_name';

or

 Script::Carp->setup(-file => 'file_name');


When script died, messages are written to "file_name".

=head2 -log => 'log_file_name'

 use Script::Carp -log => 'log_file_name';

or

 Script::Carp->setup(-log => 'log_file_name');

It is like file, but it will not clear file content.
When script died, messages are appended to "log_file_name".

=head2 -beep

 use Script::Carp -beep;
 use Script::Carp -beep => "c d e f g";

or

 Script::Carp->setup(-beep);
 Script::Carp->setup(-beep => "c d e f g");

beep when script died. It requires Audio::Beep module.
If you use Linux, you may need to 'modprobe pcspkr", 'xset -b on'

=head2 -clip

 use Script::Carp -clip;

or

 Script::Carp->setup(-clip);

message is copied to clipboard when script died.
It requires Clipboard module.

=head1 METHOD

=head2 setup

see L<SYNOPSYS> and L<OPTIONS>

=head1 IN eval BLOCK

Script::Carp just die in eval block, error messages will be set to $@ as usual.

 use Script::Carp -stop;
 
 eval {
   die "Script::Carp is ignored?"; # Yes, Sctip::Carp is ignored.
 };
 die $@ if $@; # Script::Carp work, here.

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-script-carp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Script-Carp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Script::Carp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Script-Carp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Script-Carp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Script-Carp>

=item * Search CPAN

L<http://search.cpan.org/dist/Script-Carp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Script::Carp
