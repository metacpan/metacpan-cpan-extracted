#line 1
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
           $code = eval $code;
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

#line 84
