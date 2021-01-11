package Pod::Strip;

# ABSTRACT: Remove POD from Perl code
our $VERSION = '1.100'; # VERSION

use warnings;
use strict;

use base ('Pod::Simple');

sub new {
    my $new = shift->SUPER::new(@_);
    $new->{_code_line}=0;
    $new->code_handler(
        sub {
            # Add optional line directives
            if ($_[2]->{_replace_with_comments}) {
                if ($_[2]->{_code_line}+1<$_[1]) {
                    print {$_[2]{output_fh}} ("# stripped POD\n") x ($_[1] - $_[2]->{_code_line} -1 );
                }
                $_[2]->{_code_line}=$_[1];
            }
            print {$_[2]{output_fh}} $_[0],"\n";
            return;
       });
    return $new;
}

sub replace_with_comments {
    my $self = shift;
    $self->{_replace_with_comments} = defined $_[0] ? $_[0] : 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Strip - Remove POD from Perl code

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Pod::Strip;

    my $p=Pod::Strip->new;              # create parser
    my $podless;                        # set output string
    $p->output_string(\$podless);       # see Pod::Simple
    $p->parse_string_document($code);   # or some other parsing method
                                        #    from Pod::Simple
    # $podless will now contain code without any POD

=head1 DESCRIPTION

Pod::Strip is a subclass of Pod::Simple that strips all POD from Perl Code.

=head1 METHODS

All methods besides those listed here are inherited from Pod::Simple

=head2 new

Generate a new parser object.

=head2 replace_with_comments

Call this method with a true argument to replace POD with comments (looking like "# stripped POD") instead of stripping it.

This has the effect that line numbers get reported correctly in error
messages etc.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
