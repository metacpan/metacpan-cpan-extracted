##- Nanar <nanardon@zarb.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

package RPM4::Index;

use strict;
use warnings;

use RPM4;
use RPM4::Header;
use MDV::Packdrakeng;

use File::Temp qw(tempfile);

sub buildindex {
    my (%options) = @_;
    
    my ($pid, $pack, $h_synthesis, $h_list);
    if ($options{synthesis}) {
        $pid = open($h_synthesis, "| gzip --best > '$options{synthesis}'") or return 0;
    }
    if ($options{hdlist}) {
        $pack = MDV::Packdrakeng->new(
            archive => $options{hdlist},
            comp_level => $options{complevel},
        ) or return 0;
    }
    if ($options{list}) {
        open($h_list, ">", $options{list}) or return 0;
    }

    RPM4::parserpms(
        rpms => $options{rpms},
        callback => sub {
            my (%res) = @_;
            if(defined($options{callback})) {
                $options{callback}->(%res) or return;
            }
            defined($res{header}) or return;
            
            if ($options{synthesis}) {
                $res{header}->writesynthesis($h_synthesis, $options{filestoprovides});
            }

            if ($options{hdlist}) {
                $res{header} or return;
                # Hacking perl-URPM
                my $h = $res{header}->copy(); # Get a copy to not alter original header
                $h->addtag(1000000, 6, scalar($res{header}->fullname()) . '.rpm');
                $h->addtag(1000001, 4, (stat("$res{dir}$res{rpm}"))[7]);
                my $fh = new File::Temp( UNLINK => 1, SUFFIX => '.header');
                $h->write($fh);
                sysseek($fh, 0, 0);
                $pack->add_virtual('f', scalar($res{header}->fullname()), $fh);
                close($fh);
            }
            
            if ($options{list}) {
                print $h_list "$res{rpm}\n";
            }
            
        },
        checkrpms => $options{checkrpms},
        path => $options{path},

    );

    if ($options{synthesis}) {
        close($h_synthesis);
        waitpid $pid, 0;
    }

    if($options{list}) {
        close($h_list);
    }
    1;
}

sub buildsynthesis {
    my (%options) = @_;
    buildindex(%options);
}

# Build only an hdlist file
sub buildhdlist {
    my (%options) = @_;
    buildindex(%options);
}

sub parsehdlist {
    my (%options) = @_;
    my $pack = MDV::Packdrakeng->open(archive => $options{hdlist}) or return 0;

    my (undef, $files, undef) = $pack->getcontent();
    pipe(my $in, my $out);
    if (my $pid = fork()) {
        close($out);
        stream2header($in, 0, sub {
            #printf STDERR $header->fullname ."\n";
            $options{callback}->(
                header => $_[0],
            );
        });
        close($in);
        waitpid($pid, 0);
    } else {
        close($in);
        foreach my $h (@{$options{files} || $files || []}) {
            $pack->extract_virtual($out, $h) >= 0 or die;
        }
        close($out);
        exit;
    }
    1;
}

sub parsesynthesis {
    my (%options) = @_;

    open(my $h, "cat '$options{synthesis}' | gunzip |") or return 0;

    my %hinfo = ();
    while (my $line = <$h>) {
        chomp($line);
        my (undef, $type, $info) = split('@', $line, 3);
        my @infos = split('@', $info);
        if ($type =~ m/^(provides|requires|conflict|obsoletes)$/) {
            @{$hinfo{$type}} = @infos;
        } elsif ($type eq 'summary') {
            $hinfo{summary} = $info;
        } elsif ($type eq 'info') {
            @hinfo{qw(fullname epoch size group)} = @infos;

            my $header = RPM4::headernew();
            $header->buildlight(\%hinfo);
            $options{callback}->(
                header => $header,
            );

            %hinfo = ();
        } else {
        }
    }
    close($h);
    1;
}

1;
