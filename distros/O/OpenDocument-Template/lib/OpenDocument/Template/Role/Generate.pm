package OpenDocument::Template::Role::Generate;
{
  $OpenDocument::Template::Role::Generate::VERSION = '0.002';
}
# ABSTRACT: OpenDocument::Template role for generate

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use autodie;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Encode qw( encode );
use File::Spec::Functions;
use Template;

sub generate {
    my $self = shift;
    my $dest = shift || $self->dest;

    unless ($dest) {
        confess 'dest attr is needed';
        return;
    }

    my %config;
    $config{POST_CHOMP} = 1;
    $config{ENCODING}   = $self->encoding if $self->encoding;

    my $tt = Template->new( \%config );

    my $zip = Archive::Zip->new;
    die 'read error' unless $zip->read( $self->src ) == AZ_OK;

    for my $file ( keys %{ $self->config->{templates} } ) {
        my $content;
        $tt->process(
            catfile($self->template_dir, $file),
            $self->config->{templates}{$file},
            \$content,
        ) or die $tt->error;
        if ($self->encoding) {
            $zip->contents($file, encode($self->encoding, $content));
        }
        else {
            $zip->contents($file, $content);
        }
    }

    confess 'write error' unless $zip->writeToFileNamed( $dest ) == AZ_OK;
}

1;


=pod

=encoding utf-8

=head1 NAME

OpenDocument::Template::Role::Generate - OpenDocument::Template role for generate

=head1 VERSION

version 0.002

=head1 METHODS

=head2 generate

generate role method

=for Pod::Coverage AZ_OK

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

