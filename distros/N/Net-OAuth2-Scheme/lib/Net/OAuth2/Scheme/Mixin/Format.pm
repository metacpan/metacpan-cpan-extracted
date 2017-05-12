use strict;
use warnings;

package Net::OAuth2::Scheme::Mixin::Format;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::Format::VERSION = '0.03';
}
# ABSTRACT: the 'format' option group and 'token_validate'

use Net::OAuth2::Scheme::Option::Defines;

Define_Group token_validate => 'default';

Define_Group format => undef,
  qw(token_create
     token_parse
     token_finish
     format_no_params
   );

# FUNCTION token_validate
#   token[, send_attributes] -> invalid?[, issued, expires_in, bindings...]
# SUMMARY
#   validate a token
#   token[,attributes] are from psgi_extract or a refresh request


# default implementation
# REQUIRES
#  token_parse vtable_lookup token_finish
sub pkg_token_validate_default {
    my __PACKAGE__ $self = shift;
    my (       $parse,     $finish,    $v_lookup) = $self->uses_all
      (qw(token_parse token_finish vtable_lookup));

    $self->install( token_validate => sub {

        my ($v_id, @payload) = $parse->(@_);
        my ($error, @validator) = $v_lookup->($v_id);

        return ($error, @validator) if $error;
        return ('not_found') unless @validator;

        return $finish->(\@validator, @payload);
    });
    return $self;
}


1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::Format - the 'format' option group and 'token_validate'

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is an internal module that implements the B<token_validate> method
and provides hooks for implementing the various token formats.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

