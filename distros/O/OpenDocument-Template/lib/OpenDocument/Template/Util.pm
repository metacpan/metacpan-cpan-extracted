package OpenDocument::Template::Util;
{
  $OpenDocument::Template::Util::VERSION = '0.002';
}
# ABSTRACT: utility function for OpenDocument::Template

use strict;
use warnings;
use autodie;

use File::Path qw( make_path );
use File::Slurp;
use File::Spec::Functions qw( catfile rel2abs );
use File::pushd;
use XML::Tidy;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub update_template {
    my $self = shift;
    my $ot   = shift;

    return unless $ot;
    return unless ref $ot eq 'OpenDocument::Template';

    my %params = (
        output_dir => $ot->template_dir,
        prefix     => q{},
        force      => 0,
        @_,
    );

    make_path( $params{output_dir} ) unless -e $params{output_dir};

    my $src        = rel2abs( $ot->src );
    my $output_dir = rel2abs( $params{output_dir} );

    {
        my $dir = tempd();

        my $zip = Archive::Zip->new;
        die 'read error' unless $zip->read( $src ) == AZ_OK;

        for my $file ( keys %{ $ot->config->{templates} } ) {
            my $member = $zip->memberNamed($file);
            next unless $member;

            if ( $zip->extractMember($member) != AZ_OK ) {
                warn "$file does not exist\n";
                next;
            }

            my $tidy = XML::Tidy->new($file);
            $tidy->tidy;
            $tidy->write;

            my $text = read_file($file);
            if ( $params{prefix} ) {
                my $regexp = qr/$params{prefix}/;
                $text =~ s/${regexp}\w+/[% $& | xml %]/g;
            }

            my $dest = catfile($output_dir, $file);
            if ( -f $dest ) {
                if ($params{force}) {
                    write_file( $dest, $text ) if $params{force};
                }
                else {
                    warn "file is already exists. use --force option: $dest\n";
                }
            }
            else {
                write_file( $dest, $text );
            }
        }
    }

    return 1;
}

1;


=pod

=encoding utf-8

=head1 NAME

OpenDocument::Template::Util - utility function for OpenDocument::Template

=head1 VERSION

version 0.002

=head1 METHODS

=head2 update_template( $ot, %params )

update template.

=over

=item $ot

OpenDocument::Template object

=item prefix

match rule to convert for Template Toolkit variable

=item output_dir

directory for generated(updated) file

=item force

force overwrite if file is already existed

=back

Example:

    my $ot = OpenDocument::Template->new(
        config       => 'addressbook.yml',
        template_dir => 'template',
        src          => 'addressbook.odt',
        dest         => 'addressbook-template.odt',
    );
    OpenDocument::Template::Util->update_template(
        $ot,
        prefix     => qr/(meta|person)\./,
    ) or "failed to update template\n";

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

