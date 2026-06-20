package ProductShotAI::SiteKit;
use strict;
use warnings;
use Exporter qw(import);

our $VERSION = "0.1.0";
our @EXPORT_OK = qw(base brand home_url workbench_url pricing_url blog_url contact_url zh_home_url localized_url site_metadata);

use constant BASE => "https://productshotai.app";
use constant BRAND => "ProductShot AI";

sub base { BASE }
sub brand { BRAND }

sub _page_url {
    my ($path) = @_;
    $path = "/" unless defined $path && length $path;
    $path = "/$path" unless $path =~ m{^/};
    my $clean = $path eq "/" ? "/" : $path =~ s{/+$}{}r . "/";
    return BASE . $clean;
}

sub localized_url {
    my ($locale, $path) = @_;
    return _page_url($path) if defined $locale && $locale eq "en";
    if (defined $locale && ($locale eq "zh" || $locale eq "zh-CN")) {
        $path = "/" unless defined $path && length $path;
        $path = "/$path" unless $path =~ m{^/};
        return _page_url("/zh" . ($path eq "/" ? "" : $path));
    }
    die "unsupported locale: " . (defined $locale ? $locale : "");
}

sub home_url { _page_url("/") }
sub workbench_url { BASE . "/#workbench" }
sub pricing_url { BASE . "/#pricing" }
sub blog_url { _page_url("/blog") }
sub contact_url { _page_url("/contact") }
sub zh_home_url { localized_url("zh", "/") }

sub site_metadata {
    return {
        name => BRAND, homepage => BASE,
        description => "AI product photography generator for ecommerce sellers.",
        canonical_pages => { home => home_url(), workbench => workbench_url(), pricing => pricing_url(), blog => blog_url(), contact => contact_url(), zh_home => zh_home_url() },
        tags => ["productshot", "ai-product-photography", "ecommerce-product-photos", "url-helpers"],
    };
}

1;
__END__

=head1 NAME

ProductShotAI::SiteKit - public URL helpers for ProductShot AI

=cut
