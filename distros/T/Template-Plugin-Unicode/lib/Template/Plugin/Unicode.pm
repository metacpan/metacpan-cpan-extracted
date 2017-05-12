package Template::Plugin::Unicode;
$Template::Plugin::Unicode::VERSION = '0.03';
use strict;
use warnings;
use base qw/Template::Plugin/;

# ABSTRACT: insert characters via unicode codepoints.


sub codepoint2char {
    my ($self, $input) = @_;
    return chr(hex($input));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::Unicode - insert characters via unicode codepoints.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Template;
    my $tt = Template->new;
    my $template = '[% USE Unicode %][% Unicode.codepoint2char('0x263A') %]';
    my $smiley;
    $tt->process( \$template, {}, \$smiley )
        or die $tt->error();
    say $smiley;

=head1 DESCRIPTION

Insert characters via unicode codepoints.

=head1 SEE ALSO

Another way of inserting characters via unicode codepoints is by
adding a sub ref to the \%vars hashref passed to process().

    my $u    = sub { chr(hex($_[0])) };
    my $text = '[% u('0x263a') %]';
    process(\$text, { u => sub {} }, $output);

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
