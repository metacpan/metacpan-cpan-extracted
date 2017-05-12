package Test::Perl::Tags;

use strict; use warnings;
use parent 'Test::Builder::Module';

use Path::Tiny 'path';

our @EXPORT = qw(tag_ok);
our $VERSION = '0.32';

=head1 NAME

Test::Perl::Tags - testing output of L<Perl::Tags>

=head1 SYNOPSIS

    use Test::Perl::Tags;

    # do some tagging
    
    tag_ok $tagger,
        SYMBOL => 'path/to/file.pm' => 'searchable bookmark',
        'Description of this test';

    tag_ok $tagger,
        SYMBOL => 'path/to/file.pm' => 'searchable bookmark' => 'p' => 'line:3' => 'class:Test',
        'Add additional parameters for exuberant extension';

=cut

sub tag_ok {
    my ($tagger, $symbol, $path, $bookmark) = splice(@_, 0, 4);
    my $description = pop;

    my $canonpath = path($path)->absolute->canonpath;

    my $tag = join "\t",
        $symbol,
        $canonpath,
        "/$bookmark/";

    # exuberant extensions
    if (@_) {
        $tag .= join "\t",
            q<;">,
            @_; 
    }

    my $ok = $tagger =~ /
            ^
            \Q$tag\E
            $
            /mx;
    my $builder = __PACKAGE__->builder;

    $builder->ok( $ok, $description )
        or $builder->diag( "Tags did not match:\n$tag" );
}

1;
