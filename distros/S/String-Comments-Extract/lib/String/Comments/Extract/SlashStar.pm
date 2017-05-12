package String::Comments::Extract::SlashStar;

use strict;
use warnings;

use String::Comments::Extract;

sub extract_comments {
    my $self = shift;
    my $input = shift;
    return String::Comments::Extract::_slash_star_extract_comments($input);
}

sub extract {
    return shift->extract_comments(@_);
}

sub collect_comments {
    my $self = shift;
    my $input = shift;
    my @comments;
    my $comments = String::Comments::Extract::_slash_star_extract_comments($input);
    while ($comments =~ m{/\*(.*?)\*/|//(.*?)$}msg) {
        next unless defined $1 || defined $2;
        push @comments, defined $1 ? $1 : $2;
    }
    return @comments;
}

sub collect {
    return shift->collect_comments(@_);
}

1;
