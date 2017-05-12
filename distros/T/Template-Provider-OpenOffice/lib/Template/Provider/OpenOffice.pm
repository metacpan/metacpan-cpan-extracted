package Template::Provider::OpenOffice;

use strict;
use warnings;
use OpenOffice::OODoc::File;

use base qw/Template::Provider/;

our $VERSION = '0.01';

# Basic extension of base class with undefined OO_DOC
sub new {
    my $class   = shift;
    my $options = shift || {};
    my $self    = $class->SUPER::new( $options );

    $self->{OO_DOC} = "";

    return $self;
}

# Used to get the OO_DOC object once created (for use by _output) in main Template
sub get_oo {
  my $self = shift;
  return $self->{OO_DOC};
}

# Overload our _load function to extract our xml from the openoffice file
# borrowed a bit from the Template::Provider

sub _load {
    my ($self, $name, $alias) = @_;
    my ($data, $error);
    my $now = time;

    $alias = $name unless defined $alias or ref $name;

    $self->debug("_load($name, ", defined $alias ? $alias : '<no alias>', 
                 ')') if $self->{ DEBUG };

    if (ref $name) {
        return (undef, Template::Constants::STATUS_DECLINED) if ($self->{ TOLERANT });
        return ("$alias: GLOB/References not supported",Template::Constants::STATUS_ERROR);
    }
    elsif (-f $name) {
        my $text;

        eval {
          local $SIG{'__WARN__'} = sub { die $_[0]} ;

          # Don't attempt to read if we don't have a valid archive
          if ($self->{OO_DOC} = OpenOffice::OODoc::File->new($name)) {
              $text = $self->{OO_DOC}->extract('content.xml');
          }
        };

        $error = $@;

        unless ($text) {
            return (undef, Template::Constants::STATUS_DECLINED) if ($self->{ TOLERANT });
            return ("$alias: $error", Template::Constants::STATUS_ERROR);
        }

        $data = {
            name => $alias,
            path => $name,
            text => $text,
            time => (stat $name)[9],
            load => $now,
         };
    }
    else {
        ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
    }
   
    $data->{ path } = $data->{ name }
        if $data and ref $data and ! defined $data->{ path };

    return ($data, $error);
}

=head1 NAME

Template::Provider::OpenOffice - OpenOffice (ODT) Provider for Template Toolkit

=head1 SYNOPSIS

=head1 DESCRIPTION

This module extends Template::Provider to automatically extract the 
content.xml file from an OpenOffice zip file and run it through
Template::Toolkit for processing.

We use OpenOffice::OODoc to actually open the document and extract
the content.xml file.  This gives us the benefit of having the
methods available to add/subtract files in addition to parsing
and processing the content file if we want to do some custom work
in addition to templating.

=head1 AUTHOR

Andy Brezinsky E<lt>abrezinsky@brevient.comE<gt>

=head1 VERSION

Template::Provider::OpenOffice version 0.01, released 20 Sept 2006

=head1 COPYRIGHT

  Copyright (C) 2006 Brevient Technologies, Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
