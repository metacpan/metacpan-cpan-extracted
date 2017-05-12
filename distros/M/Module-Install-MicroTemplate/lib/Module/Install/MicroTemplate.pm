package Module::Install::MicroTemplate;
use strict;
use warnings;
our $VERSION = '0.01';
use 5.008_001;
use base qw(Module::Install::Base);

sub render_mt {
    my $self = shift;
    return unless $Module::Install::AUTHOR;

    my ($src, $dst) = @_;

    $self->postamble(<<"...");
$dst: $src
	$^X -Iinc -e 'use Module::Install::MicroTemplate; Module::Install::MicroTemplate->_render()' "$src" "$dst"
...

    $self->build_requires( 'Text::MicroTemplate' => '0.05' );
}

sub _render {
    die "[BUG] The number of \@ARGV should be 2.but you gave @{[ scalar @ARGV ]}" unless @ARGV == 2;
    my ($src, $dst) = @ARGV;
    require Text::MicroTemplate;

    my $tmpl = sub {
        my $fname = shift;
        open my $fh, '<', $fname or die $!;
        my $out = do { local $/; <$fh> };
        close $fh;
        return $out;
    }->($src);

    my $content = sub {
        my $tmpl = shift;
        my $mt   = Text::MicroTemplate->new(
            template    => $tmpl,
            escape_func => undef, # do not escape!
        );
        my $code = $mt->code;
           $code = eval $code; ## no critic
        die $@ if $@;
        $code->();
    }->($tmpl);


    sub {
        my ( $content, $ofname ) = @_;
        open my $fh, '>', $ofname or die "cannot open file: $ofname: $!";
        print $fh $content;
        close $fh;
    }->($content, $dst);
}

1;
__END__

=head1 NAME

Module::Install::MicroTemplate - rendering template automatically

=head1 SYNOPSIS

    use inc::Module::Install;

    render_mt 'Foo.xs.mt' => 'Foo.xs';

=head1 DESCRIPTION

This module allows you can write XS code in DRY policy by L<Text::MicroTemplate>.

In some time, you want to preprocess your XS code, like following:

    void
    set_user(const char * s)
        foo_set_user(s)

    void
    set_password(const char * s)
        foo_set_password(s)

I want to write like following:

    ? for my $v (qw/user password/) {
    void
    set_<?= $v ?>(const char * s)
        foo_set_<?= $v ?>(s)
    ? }

Of course, you can use this module for any file other than XS =)

=head1 METHODS

=over 4

=item render_mt $src => $dst;

Render the template $src using Text::MicroTemplate and write to $dst.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom  slkjfd gmail.comE<gt>

=head1 SEE ALSO

L<Text::MicroTemplate>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
