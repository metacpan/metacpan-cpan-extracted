package ModPerl::PackageRegistry;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Apache2::Const qw(TAKE1 OR_ALL DECLINED NOT_FOUND SERVER_ERROR FORBIDDEN);
use Apache2::RequestRec ();
use Apache2::CmdParms ();
use Apache2::Directive ();
use Apache2::Log ();
use Apache2::Module ();

use base q(Apache2::Module);
use Carp;

__PACKAGE__->add([ CookOptions(
    [
        'PackageNamespace',
        'Namespace under which all handlers live',
    ],
    [
        'PackageBase',
        'URI that maps to PackageNamespace (default: /)',
    ],
    [
        'PackageHandler',
        'Handler function (or ->method) (default: "handler")',
    ],
    [
        'PackageIndex',
        'Class to look for when a directory index is requested',
    ],
)]);

return 1;

# Setup

sub CookOptions { return(map { CookOption(@$_) } @_); }

sub CookOption {
    my($option, $help) = @_;
    return +{
        name            =>      $option,
        func            =>      join('::', __PACKAGE__, 'SetOption'),
        args_how        =>      TAKE1,
        req_override    =>      OR_ALL,
        $help ? (errmsg =>      "$option: $help") : (),
    };
}

sub SetOption {
    my($self, $param, $value) = @_;
    $self->{$param->directive->directive} = $value;
}

sub config {
    my $r = shift;
    my $dir_config = __PACKAGE__->get_config($r->server, $r->per_dir_config) || {};
    my $srv_config = __PACKAGE__->get_config($r->server);
    my $config = { %$srv_config, %$dir_config };
    $config;
}

# Handler

sub handler {
    my $r = shift;
    my $uri = $r->uri;
    my $config = config($r);
    my $base = $config->{PackageBase} || '/';
    my $ns;
    
    return DECLINED
        unless(substr($r->uri, 0, length $base) eq $base);
            
    unless($ns = $config->{PackageNamespace}) {
        $r->log->crit(qq{$uri: PackageNamespace is not defined!});
        return SERVER_ERROR;
    }
            
    my $path = substr($r->uri, length $base);

    if($path =~ m{[; ]}) {
        $r->log->error("$uri: HACKING ATTEMPT: URI with a space or semicolon in it's name!");
        return FORBIDDEN;
    }
    
    $path =~ s{^/}{}g;
    $path =~ s{\..+$}{};
    $path =~ s{/}{::}g;
        
    if($path =~ m{::$} || !$path) {
        if(my $index = $config->{PackageIndex}) {
            $path .= $index;
        } else {
            $r->log->error("$uri has no PackageIndex defined");
            return NOT_FOUND;
        }
    }
    
    my $pkg = join('::', $ns, $path);

    my $handler = $config->{PackageHandler} || 'handler';
    my @argv = ($r);
    
    if($handler =~ s{^-\>}{}) {
        unshift(@argv, $pkg);
    }
    
    my $func;
    
    unless($func = $pkg->can($handler)) {
        eval "use $pkg;";
        
        if($@ =~ m{Can't locate .+? in \@INC}) {
            $r->log->error(qq{$uri: $@});
            return NOT_FOUND;
        } elsif($@) {
            $r->log->crit(qq{$uri: use "$pkg" failed: $@});
            return SERVER_ERROR;
        }
        
        unless($func = $pkg->can($handler)) {
            $r->log->crit(
                qq{$uri: "$pkg" does not provide a "$handler" function/method.}
            );
            return SERVER_ERROR;
        }
    }
    
    return $func->(@argv);
}

__END__
=pod

=head1 NAME

ModPerl::PackageRegistry - Map URIs to perl package namespaces

=head1 SYNOPSIS

=head2 Apache:

 <Location /dynamic>
  SetHandler perl-script
  PerlResponseHandler ModPerl::PackageRegistry
  PackageNamespace MyWebsite::pages
  PackageBase /dynamic
  PackageIndex index
  PackageHandler ->page
 </Location>

=head2 Perl:

 package MyWebsite::pages::index;

 use strict;
 use warnings;
 
 use Apache2::RequestRec ();
 use Apache2::Const q(OK);
 
 return 1;
 
 sub page {
     my($class, $r) = @_;
     $r->do_stuff();
     return OK;
 }

=head1 DESCRIPTION

This mod_perl2 handler allows you to directly map a path in your apache 2.x
server to a package namespace in perl. When the handler is invoked, it
transforms the URI requested into the name of a perl module, and if that
module is found, executes the handler specified by the C<PackageHandler>
directive.

=head1 FINDING YOUR HANDLER

The transformation is done as follows:

=over

=item * The C<PackageBase> directive is applied.

If a URI is specified in the C<PackageBase> directive, that is stripped from
the beginning of the URI in the request. (eg; if the browser requests
C</foo/bar/baz>, and C<PackageBase> is C</foo/bar>, we are going to be
searching for C</baz>.)

C<PackageBase> defaults to "/".

Note that C<ModPerl::PackageRegistry> will decline to act as a handler
if C<PackageBase> is defined, and the URL the browser requested doesn't
match it.

=item * Any file extensions are removed.

The dot (.) is not a good character for a perl module's name, so anything
found after it is removed. This allows you to do stuff like:

 <Files "*.pr">
  SetHandler perl-script
  PerlResponseHandler ModPerl::PackageRegistry
  PackageNamespace MyPackage::foo
 </Files>

Then, if somebody requested C</some/stuff.pr>, C<ModPerl::PackageRegistry>
would look for a handler in C<MyPackage::foo::some::stuff>.

=item * Slashes are converted to double-colons (::)

This is pretty self-explanitory; the web's namespace separator is C</>,
whereas perl's is C<::>.

=item * C<PackageNamespace> is prepended to the package's name.

Again, pretty self-explanitory; if C<PackageNamespace> is C<foo> and
we're looking for C<bar::baz>, the actual package we're going to try
to load is C<foo::bar::baz>.

=item * C<PackageIndex> is applied if the request is for a directory.

The C<PackageIndex> parameter allows you to specify what to append to
the package name if a directory was requested. For example, if somebody
requested C</somewhere/else> and C<PackageIndex> was set to C<hello>,
we would be looking for C<MyPackage::foo::somehwere::else::hello>.

=back

We then attempt to load the module. If loading the module is successful,
then we try to invoke it's handler. The handler is specified by the
C<PackageHandler> directive. (By default, it is set to the mod_perl
default, C<handler>). If you would like your handler to be invoked as
a method rather than a function, then place a "->" in front of the method's
name, like so:

 PackageHandler ->method
 
At that point, C<ModPerl::PackageRegistry> is done it's work and the
rest is up to you!

=head1 NOTES

=head2 The Directory Must Exist

Apache needs to be able to at least find a directory to serve from,
even if the content it's serving is from a perl namespace. One way
around this is to make your DocumentRoot the start of your perl namespace, eg:

 DocumentRoot /usr/local/lib/perl/5.8.4/MyWebsite/pages

=head2 PackageIndex

PackageIndex will only work correctly if ModPerl::PackageRegistry is
the handler for your entire directory tree. This is because of the
way Apache interprets the C<DirectoryIndex> directive.

If you have a handler for ".pl" files, that handler will be invoked
when you request /foo.pl, B<whether or not foo.pl actually exists>.

However, if you request /, and that is resolved to /index.pl by a
C<DirectoryIndex> directive, index.pl B<must> exist or else apache2
will return a C<NOT_FOUND> response without ever invoking your handler.

If you wish to mix static and dynamic content in the same directory tree,
there are three ways (that I know of) to get around this problem.

=over

=item * Make stub files for all of your indexes

If you have an empty file called C<index.whatever> in each of your directories,
that will cause your handler to be invoked as usual.

=item * Make your DocumentRoot your perl namespace's root.

Also solves the "Directory Must Exist" problem above, but this means that
you have to scatter your static content around with your perl modules.
(Is that actually such a bad thing?)

=item * Use a LocationMatch directive to force apache to use your handler for directories

Like so:

 <LocationMatch "/$">
  SetHandler perl-script
  PerlResponseHandler ModPerl::PackageRegistry
  PackageIndex index
  PackageNamespace MyWebsite::pages
 </LocationMatch>

=back

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net>.

The "TestCommon::LogDiff" package, used by the test suite, was pilfered
from the mod_perl 2.0.2 distribution.

=head1 LICENSE

This is free software; you may redistribute it under the same terms as
perl itself.

=cut
