package Term::ProgressBar::Color;

our $VERSION = '0.00'; # VERSION

1;
# ABSTRACT: Provide a progress meter on a standard terminal (with color)


__END__
=pod

=head1 NAME

Term::ProgressBar::Color - Provide a progress meter on a standard terminal (with color)

=head1 VERSION

version 0.00

=head1 SYNOPSIS

 # use via Progress::Any

 use Progress::Any::Output;
 Progress::Any::Output->set('TermProgressBarColor',
                            width=>50, color_theme=>"Default::Foo");

=head1 DESCRIPTION

There is actually no Term::ProgressBar::Color. The actual package is
L<Progress::Any::Output::TermProgressBarColor>. You use it via L<Progress::Any>.

=head1 SEE ALSO

L<Term::ProgressBar>

L<Progress::Any>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

