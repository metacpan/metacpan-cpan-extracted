package Parse::Fedora::Packages;
use strict;
use warnings;

use Archive::Extract;
use XML::Simple  qw(XMLin);
use Data::Dumper qw(Dumper);
use Carp         qw();
use LWP::UserAgent;


our $VERSION = '0.06';

=head1 NAME

Parse::Fedora::Packages - Parse Fedora package information

=head1 SYNOPSIS

 use Parse::Fedora::Packages;
 my $p = Parse::Fedora::Packages->new;
 $p->parse_primary("primary.xml");

 my @all = $p->list_packages();

 print $all[0]->{name};
 print $all[0]->{version};
 print $all[0]->{summary};
 print $all[0]->{description};
 print $all[0]->{url};

=head1 METHODS


=cut

=head2 new

Constructor

  my $p = Parse::Fedora::Packages->new

=cut

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;

    return $self;
}

=head2 parse_primary

Given a primary.xml file it will read it into memory and parse it.

Returns nothing.

Throws exception if the file is invalid xml.

   $p->parse_primary("primary.xml");

=cut

sub parse_primary {
    my ($self, $filename) = @_;
    #if (-e $filename
    $self->{xml} = XMLin($filename, ForceArray => 1, KeyAttr => []);
    # keys of xml: packages, xmlns, xmlns:rpm package
    # value of package is an array
    #print "$xml->{package}\n";
    #print join "\n", keys %{ $xml->{packages} };
    #print Dumper $self->{xml}->{package};
    #print join "\n", @{ $xml->{package} };

    return;
}

=head2 parse_primary_gz

Given a primary.xml.gz file it will read it into memory and parse it. If a URL is passed as argument, it will download it.

Returns nothing.

   $p->parse_primary_gz('primary.xml');

   # Or

   $p->parse_primary_gz('http://mirror.yandex.ru/fedora/tigro/non-free/11/i386/repodata/primary.xml.gz');

=cut

sub parse_primary_gz {

    my ($self, $gz) = @_;
    my $gz_file;
    if ($gz =~ /^(?:https?)|(?:ftps?):\/\//) {
    						my $ua = LWP::UserAgent->new;
    						$ua->agent("Parse::Fedora::Packages $VERSION");
						($gz_file) = $gz =~ /.+\/(.*?\.gz)$/;
    						my $response = $ua->get($gz,':content_file' => $gz_file);            # File is created here
    						if (!$response->is_success) { Carp::croak $response->status_line; }
    					     }
    					     
    else { $gz_file = $gz; }
    
    my $ae = Archive::Extract->new( archive => $gz_file);
    my $ok = $ae->extract or Carp::croak $ae->error;
    my $file_list = $ae->files;

    my $xml_file = @$file_list[0];
    $self->{xml} = XMLin($xml_file, ForceArray => 1, KeyAttr => []);

    ### Cleaning up mess
    
    unlink($gz_file);
    for (@$file_list) { unlink $_; }
    return;
    
    
        					     
    


}

=head2 reported_count_packages

returns list of packages (sub xml)

=cut

sub reported_count_packages {
    my ($self) = @_;
    return $self->{xml}{packages};
}

=head2 count_packages

returns number of packages

=cut

sub count_packages {
    my ($self) = @_;
    return scalar @{ $self->{xml}{package} };
}


=begin doc

          {
            'location' => [
                          {
                            'href' => 'Fedora/RPMS/perl-IO-Socket-INET6-2.51-2.fc6.noarch.rpm'
                          }
                        ],
            'time' => [
                      {
                        'file' => '1160093979',
                        'build' => '1152725912'
                      }
                    ],
            'version' => [
                         {
                           'rel' => '2.fc6',
                           'epoch' => '0',
                           'ver' => '2.51'
                         }
                       ],
            'arch' => [
                      'noarch'
                    ],
            'name' => [
                      'perl-IO-Socket-INET6'
                    ],
            'packager' => [
                          'Red Hat, Inc. <http://bugzilla.redhat.com/bugzilla>'
                        ],
            'description' => [
                             'Perl Object interface for AF_INET|AF_INET6 domain sockets'
                           ],
            'size' => [
                      {
                        'archive' => '23524',
                        'installed' => '22457',
                        'package' => '13579'
                      }
                    ],
            'checksum' => [
                          {
                            'pkgid' => 'YES',
                            'content' => '2bd89bfbb33a979ed0555c4def384dfe58d5f989',
                            'type' => 'sha'
                          }
                        ],
            'format' => [
                        {
                          'rpm:provides' => [
                                            {
                                              'rpm:entry' => [
                                                             {
                                                               'epoch' => '0',
                                                               'flags' => 'EQ',
                                                               'ver' => '2.51',
                                                               'name' => 'perl(IO::Socket::INET6)'
                                                             },
                                                             {
                                                               'rel' => '2.fc6',
                                                               'epoch' => '0',
                                                               'flags' => 'EQ',
                                                               'ver' => '2.51',
                                                               'name' => 'perl-IO-Socket-INET6'
                                                             }
                                                           ]
                                            }
                                          ],
                          'rpm:buildhost' => [
                                             'ia64-1.build.redhat.com'
                                           ],
                          'rpm:vendor' => [
                                          'Red Hat, Inc.'
                                        ],
                          'rpm:license' => [
                                           'Artistic or GPL'
                                         ],
                          'rpm:group' => [
                                         'Development/Libraries'
                                       ],
                          'rpm:requires' => [
                                            {
                                              'rpm:entry' => [
                                                             {
                                                               'name' => 'perl(:MODULE_COMPAT_5.8.8)'
                                                             },
                                                             {
                                                               'rel' => '1',
                                                               'epoch' => '0',
                                                               'flags' => 'LE',
                                                               'pre' => '1',
                                                               'ver' => '4.0',
                                                               'name' => 'rpmlib(PayloadFilesHavePrefix)'
                                                             },
                                                             {
                                                               'name' => 'perl(Exporter)'
                                                             },
                                                             {
                                                               'rel' => '1',
                                                               'epoch' => '0',
                                                               'flags' => 'LE',
                                                               'pre' => '1',
                                                               'ver' => '3.0.3',
                                                               'name' => 'rpmlib(VersionedDependencies)'
                                                             },
                                                             {
                                                               'name' => 'perl(Socket6)'
                                                             },
                                                             {
                                                               'name' => 'perl(Carp)'
                                                             },
                                                             {
                                                               'name' => 'perl(IO::Socket)'
                                                             },
                                                             {
                                                               'name' => 'perl(Errno)'
                                                             },
                                                             {
                                                               'rel' => '1',
                                                               'epoch' => '0',
                                                               'flags' => 'LE',
                                                               'pre' => '1',
                                                               'ver' => '3.0.4',
                                                               'name' => 'rpmlib(CompressedFileNames)'
                                                             },
                                                             {
                                                               'name' => 'perl(Socket)'
                                                             },
                                                             {
                                                               'name' => 'perl(strict)'
                                                             }
                                                           ]
                                            }
                                          ],
                          'rpm:sourcerpm' => [
                                             'perl-IO-Socket-INET6-2.51-2.fc6.src.rpm'
                                           ],
                          'rpm:header-range' => [
                                                {
                                                  'end' => '3228',
                                                  'start' => '440'
                                                }
                                              ]
                        }
                      ],
            'summary' => [
                         'Perl Object interface for AF_INET|AF_INET6 domain sockets'
                       ],
            'url' => [
                     'http://search.cpan.org/~mondejar/IO-Socket-INET6/'
                   ],
            'type' => 'rpm'
          },

=end doc

=cut

sub list_packages {
    my ($self, %args) =  @_;
    my $name = qr//;
    if ($args{name}) {
        if (ref $args{name}) {
            if (ref($args{name}) eq 'REF') {
                $name = $args{name};
            } else {
                Carp::croak("name must be either a simple string or a regular expression created by qr//");
            }
        } else {
            $name = qr/$args{name}/;
        }
    }
    #return grep { print STDERR "$_->{name}[0]\n" } @{ $self->{xml}{package} };

    return map { {
                    name => $_->{name}[0],
                    version => $_->{version}[0]{ver},
                    description => eval { 
                    			  $_->{description}[0] =~ s/\n/\ /g;
                    			  return $_->{description}[0];
                    			},
                    summary => $_->{summary}[0],
                    url => $_->{url}[0],
                    
                 } } 
           grep { $_->{name}[0] =~ /$name/ } @{ $self->{xml}{package} };
}

=head1 WARNING

This is an alpha relese, The API will change.

=head1 TODO

Provide parse_primary_gz("primary.xml.gz");

=head1 AUTHORS

Gabor Szabo, E<lt>gabor@pti.co.ilE<gt>

Currently maintained by rarbox, E<lt>rarbox@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2008 Gabor Szabo <gabor@pti.co.il>. All Rights Reserverd.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Parse::Debian::Packages>, L<Module::Packaged>, L<Module::Packaged::Report>

=cut

1;
