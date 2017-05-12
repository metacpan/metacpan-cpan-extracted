--- lib/Plack/Middleware/Auth/Form.pm.orig	2011-08-04 12:59:06.000000000 -0700
+++ lib/Plack/Middleware/Auth/Form.pm	2012-05-23 06:42:33.000000000 -0700
@@ -6,7 +6,7 @@
 }
 
 use parent qw/Plack::Middleware/;
-use Plack::Util::Accessor qw( secure authenticator no_login_page after_logout ssl_port );
+use Plack::Util::Accessor qw( secure authenticator no_login_page after_logout ssl_port logout_hook );
 use Plack::Request;
 use Scalar::Util;
 use Carp ();
@@ -21,6 +21,12 @@
     } elsif (ref $auth ne 'CODE') {
         die 'authenticator should be a code reference or an object that responds to authenticate()';
     }
+
+    if ($self->logout_hook) {
+	if (ref $self->logout_hook ne 'CODE') {
+	    die 'logout_hook should be a code reference';
+	}
+    }
 }
 
 sub call {
@@ -129,6 +135,11 @@
 sub _logout {
     my($self, $env) = @_;
     if( $env->{REQUEST_METHOD} eq 'POST' ){
+	if ($self->logout_hook) {
+	    if (ref $self->logout_hook eq 'CODE') {
+		$self->logout_hook->( $env->{'psgix.session'}{user_id}, $env );
+	    }
+	}
         delete $env->{'psgix.session'}{user_id};
     }
     return [ 
