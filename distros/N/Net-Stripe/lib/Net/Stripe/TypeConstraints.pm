package Net::Stripe::TypeConstraints;
$Net::Stripe::TypeConstraints::VERSION = '0.42';
use strict;
use Moose::Util::TypeConstraints qw/subtype as where message enum/;

# ABSTRACT: Custom Moose TypeConstraints for Net::Stripe object attributes and parameters

subtype 'StripeTokenId',
    as 'Str',
    where {
        /^tok_.+/
    },
    message {
        sprintf( "Value '%s' must be a token id string of the form tok_.+", $_ );
    };

subtype 'StripeCardId',
    as 'Str',
    where {
        /^card_.+/
    },
    message {
        sprintf( "Value '%s' must be a card id string of the form card_.+", $_ );
    };

subtype 'StripeCustomerId',
    as 'Str',
    where {
        /^cus_.+/
    },
    message {
        sprintf( "Value '%s' must be a customer id string of the form cus_.+", $_ );
    };

subtype 'StripeResourceObject',
    as 'Object',
    where {
        ( $_->isa( 'Net::Stripe::Resource' ) || $_->isa( 'Net::Stripe::Card' ) ) && $_->can( 'form_fields' )
    },
    message {
        sprintf( "Value '%s' must be an object that inherits from Net::Stripe::Resource with a 'form_fields' method", $_ );
    };

subtype 'StripeSourceId',
    as 'Str',
    where {
        /^src_.+/
    },
    message {
        sprintf( "Value '%s' must be a source id string of the form src_.+", $_ );
    };

# ach_credit_transfer, ach_debit, alipay, bancontact, card, card_present, eps,
# giropay, ideal, multibanco, klarna, p24, sepa_debit, sofort, three_d_secure,
# or wechat
enum 'StripeSourceType' => [qw/ ach_credit_transfer card /];

enum 'StripeSourceUsage' => [qw/ reusable single_use /];

enum 'StripeSourceFlow' => [qw/ redirect receiver code_verification none /];

subtype 'EmptyStr',
    as 'Str',
    where {
        $_ eq ''
    },
    message {
        sprintf( "Value '%s' must be an empty string", $_ );
    };

subtype 'StripeProductId',
    as 'Str',
    where {
        /^prod_.+/
    },
    message {
        sprintf( "Value '%s' must be a product id string of the form prod_.+", $_ );
    };

enum 'StripeProductType' => [qw/ good service /];

subtype 'StripeAPIVersion',
    as 'Str',
    where {
        /^\d{4}-\d{2}-\d{2}$/
    },
    message {
        sprintf( "Value '%s' must be a Stripe API version string of the form yyyy-mm-dd",
            $_,
        );
    };

subtype 'StripePaymentMethodId',
    as 'Str',
    where {
        /^pm_.+/
    },
    message {
        sprintf( "Value '%s' must be a payment method id string of the form pm_.+", $_ );
    };

subtype 'StripePaymentIntentId',
    as 'Str',
    where {
        /^pi_.+/
    },
    message {
        sprintf( "Value '%s' must be a payment intent id string of the form pi_.+", $_ );
    };

enum StripePaymentMethodType => [qw/ card sepia_debit ideal /];

enum StripeCaptureMethod => [qw/ automatic manual /];

enum StripeConfirmationMethod => [qw/ automatic manual /];

enum StripeCancellationReason => [qw/ duplicate fraudulent requested_by_customer abandoned /];

enum StripeSetupFutureUsage => [qw/ on_session off_session /];

1;

__END__

=pod

=head1 NAME

Net::Stripe::TypeConstraints - Custom Moose TypeConstraints for Net::Stripe object attributes and parameters

=head1 VERSION

version 0.42

=head1 AUTHORS

=over 4

=item *

Luke Closs

=item *

Rusty Conover

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Prime Radiant, Inc., (c) copyright 2014 Lucky Dinosaur LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
