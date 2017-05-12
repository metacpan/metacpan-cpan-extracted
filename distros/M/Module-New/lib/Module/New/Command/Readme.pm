package Module::New::Command::Readme;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;

functions {

  create_readme_from_pod => sub () { Module::New::Queue->register(sub {
    my ($self, $file) = @_;
    croak "source file is required" unless $file && -f $file;
    my $context = Module::New->context;
    my $readme = $context->path->file('README');

    require Pod::Text;
    my $parser = Pod::Text->new(width => 68, indent => 2);
    $parser->output_string(\my $pod);
    $parser->parse_file($file);
    $readme->spew($pod);
    $context->log( info => "created README" );
  })},
};

1;

__END__

=encoding utf-8

=head1 NAME

Module::New::Command::Readme

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
