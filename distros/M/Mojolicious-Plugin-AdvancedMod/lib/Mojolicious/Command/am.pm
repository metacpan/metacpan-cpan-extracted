package Mojolicious::Command::am;

use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(class_to_file class_to_path dumper slurp);

###############################################################

has description => "AdvancedMod alias.\n";
has usage       => _usage();

###############################################################

my @actions  = qw/ index show edit newf create update destroy /;
my @licenses = qw/
    perl5 artistic  artistic2
    mit   mozilla   mozilla2
    bsd   freebsd   cc0
    gpl   lgpl      gpl3
    lgpl3 agpl3     apache
    qpl/;

###############################################################

sub run {
  my $self = shift;
  my $cmd  = shift;

  if ( !$cmd ) {
    print _usage();
    return;
  }

  if ( $cmd eq 'n' ) {
    $self->new_app( @_ );
  }
  elsif ( $cmd eq 'g' ) {
    my $op = shift || '';

    if    ( $op eq 'controller' ) { $self->new_controller( @_ ); }
    elsif ( $op eq 'model' )      { $self->new_model( @_ ); }
    elsif ( $op eq 'resource' )   { $self->new_resource( @_ ); }
    else                          { die "Usage: am g [controller|model|resource]"; }
  }
  elsif ( $cmd eq 'l' ) {
    print "Licenses:\n";
    foreach my $n ( sort { $a cmp $b } @licenses ) {
      print " $n\n";
    }
  }
  else {
    # look am folder and autoload && exec code
  }
}

sub new_controller {
  my $self  = shift;
  my %opts  = _cmd_opts_parsing( \@_ );
  my $class = ref $self->app;

  $opts{handler} ||= $self->app->renderer->default_handler;
  $opts{actions} ||= \@actions;

  foreach my $name ( @_ ) {
    my $controller = "${class}::Controllers::$name";
    $self->render_to_rel_file(
      'controller',
      "lib/" . ( class_to_path $controller ),
      { ctrl      => $name,
        class     => $controller,
        actions   => $opts{actions},
        copyright => $self->copyright( \%opts )
      }
    );

    my $helper = "${class}::Helpers::$name";
    $self->render_to_rel_file(
      'helper',
      "lib/" . ( class_to_path $helper ),
      { class => $helper, copyright => $self->copyright( \%opts ) }
    );

    foreach my $action ( @{ $opts{actions} } ) {
      next if $action =~ /(create|update|destroy)/;
      $self->write_rel_file( "templates/" . lc( $name ) . "/$action.html.$opts{handler}", "It's action #$action" );
    }
  }
}

sub new_model {
  my $self  = shift;
  my %opts  = _cmd_opts_parsing( \@_ );
  my $class = ref $self->app;

  foreach my $name ( @_ ) {
    my $model = "${class}::Models::$name";
    $opts{package} ||= $model;
    $self->render_to_rel_file(
      'model',
      "lib/" . ( class_to_path $model ),
      { class => $model, copyright => $self->copyright( \%opts ) }
    );
  }
}

sub new_resource {
  my $self    = shift;
  my %opts    = _cmd_opts_parsing( \@_ );
  my $class   = ref $self->app;
  my $handler = $self->app->renderer->default_handler;

  $opts{actions} ||= \@actions;

  foreach my $name ( @_ ) {
    my $controller = "${class}::Controllers::$name";
    $self->render_to_rel_file(
      'controller',
      "lib/" . ( class_to_path $controller ),
      { ctrl      => $name,
        class     => $controller,
        actions   => \@actions,
        copyright => $self->copyright( \%opts )
      }
    );

    my $model = "${class}::Models::$name";
    $self->render_to_rel_file(
      'model',
      "lib/" . ( class_to_path $model ),
      { class => $model, copyright => $self->copyright( \%opts ) }
    );

    my $helper = "${class}::Helpers::$name";
    $self->render_to_rel_file(
      'helper',
      "lib/" . ( class_to_path $helper ),
      { class => $model, copyright => $self->copyright( \%opts ) }
    );

    foreach my $action ( @{ $opts{actions} } ) {
      next if $action =~ /(create|update|destroy)/;
      $self->write_rel_file( "templates/" . lc( $name ) . "/$action.html.$handler", "It's action #$action" );
    }
  }
}

sub new_app {
  my $self  = shift;
  my $class = shift || 'TestApp';
  my %opts  = _cmd_opts_parsing( \@_ );

  # Add default resource
  push @_, 'App';

  $opts{handler} ||= 'haml';
  $opts{actions} ||= \@actions;
  push @{ $opts{plugins} }, 'haml_renderer' if $opts{handler} eq 'haml';

  # Prevent bad applications
  die <<EOF unless $class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "TestApp".
EOF

  # Script
  my $name = class_to_file $class;
  $self->render_to_rel_file( 'mojo', "$name/script/$name", $class );
  $self->chmod_file( "$name/script/$name", 0744 );

  # Application class
  my $app = class_to_path $class;
  $opts{package} = $app;
  $self->render_to_rel_file(
    'appclass',
    "$name/lib/$app",
    { class     => $class,
      plugins   => $opts{plugins},
      handler   => $opts{handler},
      copyright => $self->copyright( \%opts )
    }
  );

  # Controllers, models, helpers, views
  foreach my $resource ( @_ ) {
    my $controller = "${class}::Controllers::$resource";
    $opts{package} = $controller;
    $self->render_to_rel_file(
      'controller',
      "$name/lib/" . ( class_to_path $controller ),
      { ctrl      => $resource,
        class     => $controller,
        actions   => $opts{actions},
        copyright => $self->copyright( \%opts )
      }
    );

    my $model = "${class}::Models::$resource";
    $opts{package} = $model;
    $self->render_to_rel_file(
      'model',
      "$name/lib/" . ( class_to_path $model ),
      { class => $model, copyright => $self->copyright( \%opts ) }
    );

    my $helper = "${class}::Helpers::$resource";
    $opts{package} = $helper;
    $self->render_to_rel_file(
      'helper',
      "$name/lib/" . ( class_to_path $helper ),
      { class => $helper, copyright => $self->copyright( \%opts ) }
    );

    foreach my $action ( @{ $opts{actions} } ) {
      next if $action =~ /(create|update|destroy)/;
      $self->write_rel_file( "$name/templates/" . lc( $resource ) . "/$action.html.$opts{handler}",
        "It's action #$action" );
    }
  }

  # Test
  $self->render_to_rel_file( 'test', "$name/t/basic.t", $class );

  # Directory's
  foreach my $dir ( qw/ log css images fonts js / ) {
    my $path = $dir eq 'log' ? "$name/$dir" : "$name/public/$dir";
    $self->create_rel_dir( $path );
  }

  # Static
  $self->render_to_rel_file( 'static', "$name/public/index.html" );

  # Templates
  $self->render_to_rel_file( 'layout', "$name/templates/layouts/default.html.$opts{handler}" );
}

sub copyright {
  my $self = shift;
  my $opts = shift;

  return '' unless $opts->{author};

  $opts->{author}  ||= "It's me";
  $opts->{year}    ||= '2014';
  $opts->{license} ||= '';

  if ( -r $opts->{license} ) {
    $opts->{license} = slurp $opts->{license};
  }
  elsif ( grep {/$opts->{license}/} @licenses ) {
    $opts->{license} = $self->render_data( "lic_$opts->{license}" );
  }

  my $pod = <<EOT;
 =encoding utf8

 =head1 NAME

##PACKAGE## - Best of the best module :)

 =head1 AUTHOR

##AUTHOR##

 =head1 COPYRIGHT

(C) ##YEAR##

 =head1 LICENSE

##LICENSE##
 =cut
EOT

  $pod =~ s/\s=//gs;
  $pod =~ s/##PACKAGE##/$opts->{package}/s;
  $pod =~ s/##AUTHOR##/$opts->{author}/s;
  $pod =~ s/##YEAR##/$opts->{year}/s;
  $pod =~ s/##LICENSE##/$opts->{license}/s;

  return $pod;
}

sub _cmd_opts_parsing {
  my ( $args, %opts ) = shift;
  my @ar_index;

  for ( my $i = 0; $i <= $#$args; $i++ ) {
    next if $args->[$i] !~ /^\w+:/;
    my ( $k, $v ) = split /:/, $args->[$i];
    push @ar_index, $i;
    $opts{$k} = $k =~ /^(handler|package|author|year|license)$/ ? $v : [ split /,/, $v ];
  }

  map { splice @$args, $_, 1 } reverse @ar_index;

  return %opts;
}

sub _usage {
  return <<USAGE;

Usage: $0 COMMAND OPTION [ARGS]

  Commands:
    n - create new application
    g - generic
    d - delete
    l - list of licenses

  Options:
    controller
    model
    resource

  Arguments:
    handler #Default: haml
    plugins
    actions
    license
    author
    year    #Default: 2014
    email

  Examples:
    # create new application
    mojo am n App
    mojo am n App license:perl5
    mojo am n App actions:new,create,update plugins:haml_renderer,dbi
    # generic new controller
    ./script/my_app am g controller Main
    # generic controller, model and view's
    ./script/my_app am g resource UserStat actions:index,edit,newf

USAGE
}

=encoding utf8

=head1 NAME

Mojolicious::Command::am - Generic L<Mojolicious> app, controllers, models, helpers, views

=head1 SYNOPSIS

  # If the application is not exist
  mojo am

  # If the application exist
  ./script/my_app am

=head1 AUTHOR

Grishkovelli L<grishkovelli@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__DATA__

@@ mojo
% my $class = shift;
#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

require Mojolicious::Commands;
Mojolicious::Commands->start_app('<%= $class %>');

@@ appclass
% my $h = shift;
package <%= $h->{class} %>;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  % if( $h->{plugins} ) {
      % foreach my $p ( @{ $h->{plugins} } ) {
  $self->plugin('<%= $p %>');
      % }
  % }

  $self->app->renderer->default_handler( '<%= $h->{handler} %>' );

  my $r = $self->routes;
  
  $r->namespaces( [
    '<%= $h->{class} %>::Controllers',
    '<%= $h->{class} %>::Models',
    '<%= $h->{class} %>::Helpers'
    ]
  );
  
  $r->get('/')->to('app#index');
}

1;

%= $h->{copyright}

@@ controller
% my $h = shift;
% $h->{ctrl} = lc( $h->{ctrl} );
package <%= $h->{class} %>;
use Mojo::Base 'Mojolicious::Controller';

% foreach my $action ( @{ $h->{actions} } ) {
sub <%= $action %> {
  my $self = shift;
  $self->render( '<%= $h->{ctrl} %>/<%= $action %>' );
}

% }

1;

%= $h->{copyright}

@@ model
% my $h = shift;
package <%= $h->{class} %>;

1;

%= $h->{copyright}

@@ helper
% my $h = shift;
package <%= $h->{class} %>;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app, $conf ) = @_;

}

1;

%= $h->{copyright}

@@ static
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to the Mojolicious real-time web framework!</title>
  </head>
  <body>
    <h2>Welcome to the Mojolicious real-time web framework!</h2>
    This is the static document "public/index.html",
    <a href="/">click here</a> to get back to the start.
  </body>
</html>

@@ layout
<!DOCTYPE html>
<html>
  <head><title><%%= title %></title></head>
  <body><%%= content %></body>
</html>

@@ test
% my $class = shift;
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('<%= $class %>');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();

@@ lic_perl5
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

@@ lic_artistic
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (1.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_1_0>

Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution. Such use shall not be
construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

@@ lic_artistic2
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@@ lic_mit
This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

@@ lic_mozilla
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
L<http://www.mozilla.org/MPL/>

Software distributed under the License is distributed on an "AS IS"
basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations
under the License.

@@ lic_mozilla2
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at L<http://mozilla.org/MPL/2.0/>.

@@ lic_bsd
This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of ___AUTHOR___'s Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@@ lic_freebsd
This program is distributed under the (Simplified) BSD License:
L<http://www.opensource.org/licenses/BSD-2-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@@ lic_cc0
This program is distributed under the CC0 1.0 Universal License:
L<http://creativecommons.org/publicdomain/zero/1.0/>

The person who associated a work with this deed has dedicated the work
to the public domain by waiving all of his or her rights to the work
worldwide under copyright law, including all related and neighboring
rights, to the extent allowed by law.

You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission. See Other
Information below.

Other Information:

* In no way are the patent or trademark rights of any person affected
by CC0, nor are the rights that other persons may have in the work or
in how the work is used, such as publicity or privacy rights. 

* Unless expressly stated otherwise, the person who associated a work
with this deed makes no warranties about the work, and disclaims
liability for all uses of the work, to the fullest extent permitted
by applicable law. 

* When using or citing the work, you should not imply endorsement by
the author or the affirmer.

@@ lic_gpl
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

@@ lic_lgpl
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

@@ lic_gpl3
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

@@ lic_lgpl3
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program.  If not, see
L<http://www.gnu.org/licenses/>.

@@ lic_agpl3
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
L<http://www.gnu.org/licenses/>.

@@ lic_apache
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

@@ lic_qpl
This program is distributed under the Q Public License (QPL-1.0):
L<http://www.opensource.org/licenses/QPL-1.0>

The Software and this license document are provided AS IS with NO
WARRANTY OF ANY KIND, INCLUDING THE WARRANTY OF DESIGN, MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE.
