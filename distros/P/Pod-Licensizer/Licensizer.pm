###########################################
package Pod::Licensizer;
###########################################
use strict;
use warnings;
use Pod::Abstract;
use Log::Log4perl qw(:easy);

our $VERSION = "0.03";

###########################################
sub new {
###########################################
    my( $class, %options ) = @_;

    my $self = {
        pa       => undef,
        file     => undef,
        org_pod  => undef,
        %options,
    };

    bless $self, $class;

    return $self;
}

###########################################
sub load_file {
###########################################
    my( $self, $file ) = @_;

    $self->{ file }    = $file;
    $self->{ pa }      = Pod::Abstract->load_file( $file );

    $self->{ org_pod } = $self->{ pa }->pod();

    return $self->{ pa };
}

###########################################
sub modified {
###########################################
    my( $self ) = @_;

    return $self->{ org_pod } ne $self->{ pa }->pod();
}

###########################################
sub write_file {
###########################################
    my( $self, $file ) = @_;

    if( !defined $file ) {
        if( defined $self->{ file } ) {
            $file = $self->{ file };
        } else {
            LOGWARN "No file defined";
            return  undef;
        }
    }

    if( ! open FILE, ">$file" ) {
        ERROR "Can't open $file: $!";
        return undef;
    }

    print FILE $self->{ pa }->pod();
    close FILE;
}

###########################################
sub as_string {
###########################################
    my( $self ) = @_;

    return $self->{ pa }->pod();
}

###########################################
sub author_patch {
###########################################
    my( $self, $text, $opts ) = @_;

    $opts = {} unless defined $opts;

    if( $opts->{author_heading} ) {
        $opts->{author_regex} = "^$opts->{author_heading}\$";
    } else {
        $opts->{author_regex} = '^AUTHORS?$';
        $opts->{author_heading} = "AUTHOR";
    }

    return $self->section_patch( $opts->{author_heading}, 
                                 $opts->{author_regex},
                                 $text,
                                 $opts );
}

###########################################
sub license_patch {
###########################################
    my( $self, $text, $opts ) = @_;

    $opts = {} unless defined $opts;
    $opts->{license_heading} = "LICENSE" if !defined $opts->{license_heading};

    return $self->section_patch( $opts->{license_heading}, 
                                 "^$opts->{license_heading}\$",
                                 $text,
                                 $opts );
}

###########################################
sub section_patch {
###########################################
    my( $self, $heading, $regex, $text, $opts ) = @_;

    my $info_prefix = "";
    $info_prefix = "(dryrun) " if $opts->{ dryrun };

    while( $text !~ /\n\n$/ ) {
        $text = "$text\n";
    }

    $text =~ s/^/    /gm if exists $opts->{mode} and 
        $opts->{mode} eq "verbatim";

    my($section_head) = $self->{pa}->select("/head1[\@heading =~ {$regex}]");

    if( $opts->{ clear } ) {
        if( defined $section_head ) {
            INFO "${info_prefix}deleting section $heading from $self->{ file }";
            if( ! $opts->{ dryrun } ) {
                $section_head->detach();
            }
        }
        return 1;
    }

    my $section_new = Pod::Abstract->load_string( $text );

    if( !defined $section_head ) {
        $section_head = Pod::Abstract->load_string( 
            "=head1 $heading\n\nBlah.\n\n" );
          # skip the root
        ($section_head) = $section_head->children();

          # find the last =head1
        my( $last_head1 ) = reverse $self->{pa}->select("/head1");
        $last_head1 = $self->{pa} unless defined $last_head1;

            $section_head->insert_after( $last_head1 );
    }

    INFO "${info_prefix}adding section $heading to $self->{ file }";
    if( ! $opts->{ dryrun } ) {
        $section_head->clear();
        $section_head->push( $section_new );
    }
}

1;

__END__

=head1 NAME

Pod::Licensizer - Keep your project's AUTHOR and LICENSE sections in sync

=head1 SYNOPSIS

    # Command line:
    $ licensizer

    # API:
    use Pod::Licensizer;

    my $licensizer = Pod::Licensizer->new();
    $licensizer->load_file( "MyModule.pm" );

    $licensizer->author_patch( 'Bodo Bravo <bodo@bravo.com>' );
    $licensizer->license_patch( 'Copyright 2011 blah blah blah' );

    $licensizer->write_file();

=head1 DESCRIPTION

Pod::Licensizer helps keeping AUTHOR and LICENSE sections in sync
across many source files in a project.

=head2 licensizer

Pod::Licensizer comes with a command line utility, C<licensizer>, 
which traverses a source tree, picks files containing POD documentation,
and refreshes their AUTHOR and LICENSE sections.

You define a C<.licensizer.yml> file at the top level of your project
containing the desired AUTHOR and LICENSE data like

    # .licensizer.yml
    author: |
      Bodo Bravo <bodo@bravo.com>
      Zach Zulu <zach@zulu.com>

    license: |
      Copyright 2002-2011 by Bodo Bravo <bodo@bravo.com> and
      Zach Zulu <zach@zulu.com>. All rights reserved.

and then simply run the C<licensizer> script. 

This is helpful if you want to add an author to your project or change the year
in the copyright notice. All you have to do is edit the C<.licensizer.yml>
file and run C<licensizer>.

Advanced format:

    # .licensizer.yml
    
    author: 
      text: |
        Mike Schilli <cpan@perlmeister.com>
      mode: verbatim
    
    license: 
      text: |
        Copyright 2011 by Mike Schilli, all rights reserved.
        This program is free software, you can redistribute it and/or
        modify it under the same terms as Perl itself.

The C<verbatim> mode setting makes sure that POD doesn't reformat the
text. This is especially useful if you use tabular data (e.g. a 
vertical column of author names).

=head2 API

=over 4

=item C<new>

Constructor.

=item C<$licensizer-E<gt>load_file( $file )>

Load and parse a file containing POD.

=item C<$licensizer->E<gt>author_patch( "author text", $opts )>

Update the POD's AUTHOR section.

=item C<$licensizer->E<gt>license_patch( "license text", $opts )>

Update the POD's LICENSE section.

=item C<$licensizer->E<gt>write_file( $filename )>

Write back the file. If $filename is omitted, the original file is 
overwritten.

=back

=head1 IS LICENSIZER A WORD?

Strictly speaking, no. But what a boring world that would be if you 
couldn't make up your own words.

=head1 LICENSE

Copyright 2011 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

    2011, Mike Schilli <cpan@perlmeister.com>
    
