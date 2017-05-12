use strict;
use warnings;

package Net::OAuth2::Scheme::Mixin::Accept;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::Accept::VERSION = '0.03';
}
# ABSTRACT: defines 'token_accept'

use Net::OAuth2::Scheme::Option::Defines;

# FUNCTION token_accept
#   token[, issue_attributes] -> error, token[, save_attributes]
# SUMMARY
#   issue_attributes and send_attributes are the same
# IMPLEMENTATION token_accept_default
#   (accept_)token_type_re = ''
#   (accept_)remove = [qw(expires_in scope refresh_token)]
#   (accept_)keep = [...] or 'everything'
# REQUIRES
#   accept_needs
#   accept_hook

Define_Group token_accept => 'default';

Default_Value accept_remove => [qw(expires_in scope refresh_token)];
Default_Value accept_keep => 'everything';

sub pkg_token_accept_default {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(accept_ => @_);

    # these two cases are probably not necessary.  In fact, now that I
    # think about it 'token_accept' for refresh tokens and authcodes
    # should be completely inaccessible to clients, but maybe I'll
    # change my mind about this...

    if ($self->uses('usage') eq 'authcode') {
        # authcode is the token string ONLY
        $self->install( token_accept => sub { return (undef, $_[0]); } );
        return $self;
    }

    # ditto...
    if ($self->uses('usage') eq 'refresh') {
        # refresh is the token string ONLY
        $self->install( token_accept => sub {
            my ($token, %params) = @_;
            $token = $params{refresh_token} if  $params{refresh_token};
            return (undef, $token);
        });
        return $self;
    }

    # now for the real stuff
    my ($token_type, $remove, $keep, $needs, $hook) = $self->uses_all
      (qw(token_type accept_remove accept_keep accept_needs accept_hook));

    $self->install( token_accept => sub {
        my ($token, %params);
        if (0 == @_ % 2) {
            # token_accept( access_token => $token [, kwd => $value]* )
            %params = @_;
            $token = delete $params{access_token}
              or return ('no_access_token');
        }
        else {
            # token_accept( $token [, kwd => $value]* )
            ($token, %params) = @_;
        }

        return ('wrong_token_type')
          if (lc($params{token_type}) ne lc($token_type));

        my ($error) = $hook->(\%params);
        return ($error) if $error;

        # (1) everything in @$needs is passed through (as %save)
        #     and we die if any of them are missing
        my @missing = ();
        my %save = map {
            my $v = $params{$_};
            push @missing,$_ if !defined($v) || !length($v);
            ($_,$v)
        } @$needs;
        return ("missing_$missing[0]") if @missing;

        # (2) if $keep is a listref,
        #     we keep JUST those additional fields (i.e., beyond @$needs)
        #     otherwise we keep everything that is not in @$remove
        if (ref $keep) {
            %params = map {$save{$_}? (): ($_,$params{$_})} @$keep;
        }
        else {
            delete @{params}{@$remove,@$needs};
        }
        return (undef, $token, %params, %save);
    });
    return $self;
}


1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::Accept - defines 'token_accept'

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an internal module that implements the B<token_accept> client method.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

