###########################################
package Perldoc::Search;
###########################################
use strict;
use warnings;

our $VERSION = "0.01";

use Pod::Simple::TextContent;
use SWISH::API::Common;
use Config;
use Cwd;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        dirs => [$Config{installsitearch},
                 $Config{installsitelib},
                 $Config{installarchlib},
                 $Config{installprivlib},
                ],
        swish_options => {
            swish_adm_dir => "$ENV{HOME}/.perldig",
        },
        %options,
    };

        # If the perl lib dir is symlinked, this
        # will figure out the real paths
    for(@{$self->{dirs}}) {
        my $cwd = cwd();
        chdir $_ or die "Cannot cwd to $_";
        $_ = File::Spec->rel2abs(".");
        chdir $cwd;
    }

    $self->{swish} = SWISH::API::Common->new(
        %{$self->{swish_options}}
    );

    bless $self, $class;
}

###########################################
sub relative {
###########################################
    my($self, $path) = @_;

    $path =~ s|^$_/|| for @{$self->{dirs}};
    return $path;
}

###########################################
sub update {
###########################################
    my($self) = @_;

        # Index all files in a directory and its subdirectories
    $self->{swish}->index(@{$self->{dirs}});
}

###########################################
sub search {
###########################################
    my($self, @terms) = @_;

    return $self->{swish}->search(@terms);
}

1;

__END__

=head1 NAME

Perldoc::Search - Index and Search local Perl Documentation

=head1 SYNOPSIS

    #######################################
    # Command line utility:
    #######################################
        # This is permanent and needs to be performed only once
        # (or if new documentation gets installed).
    $ perldig -u 

        # Then, search:
    $ perldig log AND apache AND connect
     1) CGI/Carp.pm                    2) CGI/Prototype.pm              
     3) DBI/Changes.pm                 4) DBI/Changes.pm                
    Enter number of choice:
      
    #######################################
    # API
    #######################################
    use  Perldoc::Search;

    my $searcher = Perldoc::Search->new();

        # This is permanent and needs to be performed only once
        # (or if new documentation gets installed).
    $searcher->update();

        # Then, search:
    for my $hit ($searcher->search("log AND apache")) {
        print $hit->path(), "\n";
    }

=head1 DESCRIPTION

C<Perldoc::Search> uses the swish-e engine to index the local Perl
documentation. It provides both the command line utility C<perldig>
and an API to perform searches on the index. It uses C<SWISH::API::Common> 
as the indexing and search engine.

Most likely, you will want the command line utility C<perldig>, please
check the documentation that comes with it by calling

    perldoc perldig

In case you're interested in the API, read on.

=head1 METHODS

=over 4

=item C<my $searcher = Perldoc::Search-$<gt>new()>

Instantiates a searcher object. Usually takes no parameters.

If you like to modify the searched directories or want to pass
different options to C<SWISH::API::Common>, go ahead:

    use Config;

    my $searcher = Perldoc::Search->new(
        dirs => [$Config{installsitearch},
                 $Config{installsitelib},
                 $Config{installarchlib},
                 $Config{installprivlib},
                ],
        swish_options => {
            swish_adm_dir => "$ENV{HOME}/.perldig",
        }
    );

=item C<$searcher->update()>

Update the index. This operation might take a couple of minutes.

=item C<my @hits = $searcher->search("log AND apache")>

Perform a search on the index with the given query. Returns a list of
result objects.

         # Search documents containing
         # both "foo" and "bar"
     for my $hit ($swish->search("foo AND bar")) {
         print $hit->path(), "\n";
     }

=back

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
