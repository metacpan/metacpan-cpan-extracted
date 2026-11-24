package PDL::Llama;

use 5.010;
use strict;
use warnings;
use XSLoader;
use PDL::Lite ();

our $VERSION = '0.01';

XSLoader::load('PDL::Llama', $VERSION);

1;

__END__

=head1 NAME

PDL::Llama - llama.cpp XS bindings for local LLM inference with PDL

=head1 SYNOPSIS

    use PDL::Llama;

    PDL::Llama::backend_init();
    my $info = PDL::Llama::print_system_info();
    my $mmap = PDL::Llama::supports_mmap();
    PDL::Llama::backend_free();

=head1 DESCRIPTION

C<PDL::Llama> provides XS bindings to C<libllama> (C<llama.cpp>) for local LLM
runtime inspection, GGUF model execution, and L<PDL> tensor interoperability.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
