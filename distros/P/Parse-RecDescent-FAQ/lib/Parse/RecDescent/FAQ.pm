package Parse::RecDescent::FAQ;

use vars qw($VERSION);

$VERSION = '7.5';

1;

__END__


=head1 NAME

Parse::RecDescent::FAQ - the official, authorized FAQ for Parse::RecDescent. 

=head1 DESCRIPTION

=head2 Original FAQ

You can see the original FAQ (still useful) at L<Parse::RecDescent::FAQ::Original>.
It is a document that I grew over about a decade, but I no longer have time for editing and categorizing
other people's posts to fit them into POD format and to collect answers.

=head2 Delicious Bookmarks

But I still scan Google alerts for new recdescent posts daily. You may read what I have found to be useful at my
my parse-recdescent tagged L<delicious bookmarks|http://delicious.com/metaperl/parse-recdescent>.

=head2 Mailing list

You will also find the L<mailing list archives|http://lists.perl.org/list/recdescent.html>
to be of some help or you could subscribe to
L<the mailing list|http://lists.perl.org/list/recdescent.html> itself.

=head1 Recent hot questions

I occasionally encounter a recent hot question and will post it right here

=head2 Getting the return value of the top-level rule

Even if you read the L<Parse::RecDescent> very closely, you will not be sure of how to get the return
data back from a top-level rule. All the examples are C<< $parser->startrule($text) or die >> without any
attempts to extract the return value.

However, thanks to Rob Kinyon's hard work, we have an answer:

  $tree = $parser->startrule( $text ) or die "Cannot parse"


=head1 AUTHOR

Terrence Brannon

=head1 REPO

The repo is on L<github|http://github.com/metaperl/Parse--RecDescent--FAQ>

