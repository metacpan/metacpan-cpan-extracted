use strict;
use warnings;

eval { require Test::LongString; import Test::LongString; };
my $has_test_longstring = $@ eq '';

# our own string comparison test function
sub is_same_string {
    my ($got, $expected, $name) = @_;
    if ($has_test_longstring) {
        is_string( $got, $expected, $name);
    }
    else {
        is( $got, $expected, $name);
    }
}

sub file_content {
    my ($file) = @_;
    local $/;
    open my $fh, $file or do { diag "Can't open $file: $!"; return '' };
    my $content = join '', <$fh>;
    close $fh;
    return $content;
}

1;

__END__

=head1 NAME

t::Util - Some utility functions for the tests

=
