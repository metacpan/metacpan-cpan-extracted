#!/usr/bin/perl -w

# Copyright 2012 Mathieu Alorent.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

package Parse::Arcconf;

use warnings;
use strict;

=head1 NAME

Parse::Arcconf - Parse the output of arcconf utility.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Parse::Arcconf parses the output of C<arcconf> utility to allow
programmatic access to the RAID configuration information provided by the
arcconf utility on Adaptec RAID cards.

    use Parse::Arcconf;

    my $arcconf = Parse::Arcconf->new();

Run the C<arcconf> tool directly to query the hardware (requires root):

    my $controllers = $arcconf->parse_config();
    
Parse a text file created already by running C<arcconf> tool:

    my $controllers = $arcconf->parse_config_file("foo.txt");

Read from a file descriptor already opened by the program:

    my $controllers = $arcconf->parse_config_fh(\*STDIN);

=head1 SUBROUTINES/METHODS

=head2 new

Return an instance of the Parse::Arcconf class that can be used to parse
input in one of several ways.

=cut

sub new
{
  my ($class, $config, $plugin) = @_;
  my $self = {};

  bless($self, $class);
  return $self;
}

=head2 parse_config

Attempt to run the arcconf utility, and parse the output.  This command
actually uses parse_config_fh() after opening a pipe to the relevant command.

The command that is actually run is approximately:

=over 4

arcconf GETCONFIG 1

=back

This command requires root access, and Parse::Arcconf makes no attempt to 
use sudo or any other method to gain root access.  It is recommended to call 
your script which uses this module as root.

The parse_config_fh() and parse_config_file() will expect output equivalent
to that from the above command.

=cut

sub parse_config
{
  my ($self) = @_;

  my $arcconf  = "/usr/sbin/arcconf";
  my $argument = "GETCONFIG 1";
  my $command = sprintf("%s %s|", $arcconf, $argument);

  my $fh;
  if(open $fh, $command)
  {
    my $c = $self->parse_config_fh($fh);
    close $fh;
    return $c;
  }
  return undef;
}

=head2 parse_config_file

Open and parse a file containing the output from arcconf.

=cut

sub parse_config_file
{
  my ($self, $file) = @_;

  my $fh;
  if(open $fh, "<".$file)
  {
    my $c = $self->parse_config_fh($fh);
    close $fh;
    return $c;
  }
  return undef;

}

=head2 parse_config_fh

Read from the file handle and parse it, returning a hash-of-hashes.

=cut

sub parse_config_fh
{
  my ($self, $fh) = @_;

  my $controller = {};
  my $total_controller        = 0;
  my $current_controller      = 0;
  my $current_logical_drive   = undef;
  my $current_physical_drive  = undef;
  my $ctrl                    = undef;
  my $line                    = undef;

  LEVEL1: while($line = <$fh>)
  {
    chomp $line;

    next if($line =~ /^$/);
    next if($line =~ /^-+$/);

    if($line =~ /^Controllers found: (\d+)$/) {
      $total_controller = $1;
    }

    if($line =~ /^Controller information/) {
      $current_controller     = $current_controller + 1;
      $current_logical_drive  = undef;
      $current_physical_drive = undef;
      $controller->{$current_controller} = {};
      $ctrl = $controller->{$current_controller};

      while($line = <$fh>) {
        chomp $line;

        if ($line =~ /^\s+(.*\w)\s+:\s+(.*)$/) {
          $ctrl->{$1} = $2;
        } elsif ($line =~ /^\s+-+$/) {
          last;
        }
      }

      LEVEL2: while($line = <$fh>) {
        if ($line =~ /^\s+-+$/) {
          $line = <$fh>;
          chomp $line;
	}
	if($line =~ /^\s+(.*\w)\s*/) {
		my $cat = $1;
		$line = <$fh>;
		LEVEL3: while($line = <$fh>) {
			chomp $line;

			if ($line =~ /^\s+(.*\w)\s+:\s+(.*)$/) {
				$ctrl->{$cat}{$1} = $2;
			} elsif ($line =~ /^\s+-+$/) {
				last LEVEL3;
			} elsif ($line =~ /^$/) {
				last LEVEL2;
			}
		}
        }
      }
    }

    next if(!defined($current_controller));

    if($line =~ /^Logical drive information/ or $line =~ /^Logical device information/) {
	LEVEL4: while($line = <$fh>) {
		chomp $line;

		if ($line =~ /^\S+.*\w\s+(\d+)$/) {
			$current_logical_drive = $1;
		} elsif ($line =~ /^\s+(\S.*\S+)\s+:\s+(.*)$/) {
			$ctrl->{'logical drive'}{$current_logical_drive}{$1} = $2;
		} elsif ($line =~ /^\s+-+$/) {
			my $cat = <$fh>;
                        $cat =~ s/^\s+(\S.*\S+)\s+/$1/;
			chomp $cat;
			LEVEL5: while($line = <$fh>) {
				chomp $line;

	                  	if ($line =~ /^\s+(\S.*\S+)\s+:\s+(.*)$/) {
	                  		$ctrl->{'logical drive'}{$current_logical_drive}{$cat}{$1} = $2;
	                  	} elsif ($line =~ /^\S+.*\w\s+(\d+)$/) {
                                        $current_logical_drive = $1;
	                  		last LEVEL5;
	                  	} elsif ($line =~ /^-+$/) {
	                  		last LEVEL4;
	                  	} elsif ($line =~ /^\s+-+$/) {
					next;
				}
			}
		}
    	}
    }

    if($line =~ /^Physical Device information/) {

	LEVEL2: while($line = <$fh>) {
		if ($line =~ /^\s+-+$/) {
			$line = <$fh>;
			chomp $line;
		}
		if ($line =~ /^\s+Device\s+#(\d+)$/) {
			$current_physical_drive = $1;
		} elsif ($line =~ /^\s+Device is (.*\w)/) {
			$ctrl->{'physical drive'}{$current_physical_drive}{'Device is'} = $1;
		} elsif ($line =~ /^\s+(.*\w)\s+:\s+(.*)$/) {
			$ctrl->{'physical drive'}{$current_physical_drive}{$1} = $2;
		} elsif ($line =~ /^\s+-+$/) {
			last LEVEL3;
		} elsif ($line =~ /^$/) {
			last LEVEL2;
		}
	}
    }

  }
  
  return $controller;
}

=head1 AUTHOR

Mathieu Alorent, C<< <kumy at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-arcconf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Arcconf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Arcconf


You can also look for information at:

=over 4

=item * Source code

L<https://github.com/kumy/Parse-Arcconf>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Arcconf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Arcconf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Arcconf>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Arcconf/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mathieu Alorent.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

This program is based on Parse::HP::ACU a work of Jeremy Cole.


=cut

1; # End of Parse::Arcconf
