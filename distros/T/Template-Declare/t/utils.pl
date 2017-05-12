use warnings;
use strict;

use Test::More;

sub ok_lint {
    my ($html, $ignore_chars) = @_;

SKIP:
    {
        skip "HTML::Lint not installed. Skipping", 1
            unless eval { require HTML::Lint; 1 };

        my $lint = HTML::Lint->new;
        do {
            local $SIG{__WARN__} = sub {}; # STFU HTML::Lint!
            $lint->parse($html);
        };
        # Collect the errors, ignore the invalid character errors when requested.
        my @errors = $ignore_chars
            ? grep { $_->errcode ne 'text-use-entity' } $lint->errors
            : $lint->errors;
        is( @errors, 0, "Lint checked clean" );
        foreach my $error ( @errors ) {
            diag( $error->as_string );
        }
    }

}

1;
