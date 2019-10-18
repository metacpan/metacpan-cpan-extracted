package Rapi::Blog::Util::ppRender;
use strict;
use warnings;

# ABSTRACT: Render method dispatch to template process class

use Moo;
use Types::Standard qw(:all);
use RapidApp::Util qw(:all);
require Module::Runtime;

has '_base_namespace', is => 'ro', isa => Str, default => sub {'Rapi::Blog::Template::Postprocessor'};

has '_post_processor', is => 'rw', isa => Maybe[Str], default => sub {undef};


sub AUTOLOAD {
  my $self = shift;
  my $method = (reverse(split('::',our $AUTOLOAD)))[0];
  $self->_call_process($method,@_)
}

sub _call_process {
  my ($self, $processor, $content) = @_;
  
  die "ppRender: no Postprocessor and/or content supplied" unless ($processor);
  
  # Allow us to be called with or without the name of the post-processor
  if(! $content && $self->_post_processor) {
    $content = $processor;
    $processor = $self->_post_processor
  }
  
  $content //= '';
  
  my $class = $processor =~ /\:\:/
    ? $processor
    : join('::',$self->_base_namespace,$processor);
  
  Module::Runtime::require_module($class);

  $class->can('process') or die "$class is not a Template Processor class without a ->process method";

  my $content_ref = ref $content ? $content : \$content;

  $class->process($content_ref)
}




1;


__END__

=head1 NAME

Rapi::Blog::Util::ppRender - Render method dispatch to template post-processor class


=head1 DESCRIPTION

Caller to Template Postprocessor class

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
