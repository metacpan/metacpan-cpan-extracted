use strict;
use warnings;

use Test::Most;

use Pod::Knit;

my $knit = Pod::Knit->new( config => { plugins => [ 'Abstract' ], },);

my $doc = $knit->munge_document( content => <<'END' =~ s/^    //rmg );
    package Foo;
    # ABSTRACT: Do the thing
END

like $doc->as_pod => qr/
^=head1 \s+ NAME \s+
Foo \s+ - \s+ Do \s the \s thing
/mx;

like $doc->as_string, qr/^__END__\s*^=pod/m;

done_testing;

