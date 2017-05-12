# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
#!/usr/bin/perl
my $required_svn = '1.3.0';
my $required_svm = '0.71';

use strict;
use inc::Module::Install;

name		('SVK');
author		('Chia-liang Kao <clkao@clkao.org>');
abstract	('A decentralized version control system');
license		('perl');
version_from	('lib/SVK/Version.pm');
install_script	('bin/svk');
clean_files	('t/checkout', 't/apache_svn');
requires(
    # 'SVN::Core'                => $required_svn,
    'version'                  => '0.68',
    'Algorithm::Annotate'      => '0',
    'Algorithm::Diff'          => '1.1901',
    'YAML::Syck'               => '0.60',
    'Data::Hierarchy'          => '0.30',
    'PerlIO::via::dynamic'     => '0.11',
    'PerlIO::via::symlink'     => '0.02',
    'IO::Digest'               => '0',
    'SVN::Simple::Edit'        => '0.27',
    'URI'                      => '0',
    'PerlIO::eol'              => '0.13',
    'Class::Autouse'           => '1.15',
    'App::CLI'                 => '0',
    'List::MoreUtils'          => '0',
    'Class::Accessor::Fast'    => '0',
    'Class::Data::Inheritable' => '0',
    'Path::Class'              => '0.16',
    'UNIVERSAL::require'       => '0',
    'Term::ReadKey'            => '0',
    'Time::HiRes'              => '0',       # in core since 5.7.3
    'File::Temp'               => '0.17',
    'Encode'                   => '2.10',    # in core since 5.8.7
    'Getopt::Long'             => '2.35',    # in core since 5.8.8
    'Pod::Escapes'             => '0',       # in core since 5.9.3
    'Pod::Simple'              => '0',       # in core since 5.9.3
    'File::Spec'               => '3.19',    # in core since 5.9.3
    'Time::Progress'           => '0',
);


requires(
    'Date::Format'             => '',
) if ($^O eq 'MSWin32');
build_requires(
    'Test::More'               => '0.42',
);
features(
    'Bootstrap support' => [
    -default => 1,
        'PerlIO::via::Bzip2'       => '0',
        'PerlIO::gzip'             => '0',
        'SVN::Dump'                => '0.04',
        'LWP::UserAgent'           => '0',
    ],
    'Localized messages' => [
	-default => 1,
        'Locale::Maketext::Lexicon' => '0.62',
        'Locale::Maketext::Simple'  => '0.16',
    ],
    'Message display through a pager' => [
        -default => 1,
        'IO::Pager'             => '0',
    ],
    'Log4perl support' => [
        -default => 0,
        'Log::Log4perl'         => '0',
    ]
);


if( eval{ require SVN::Mirror } ) {
    requires( 'SVN::Mirror' => $required_svm );
} else {
    features( 'SVN::Mirror support' => [
               -default => 1,
               'SVN::Mirror'    => $required_svm,
           ],
	    );
}

features(
    'Patch management' => [
	-default => 1,
	'Compress::Zlib'    => '0',
	'FreezeThaw'        => '0',
    ],
);

# Include subdirectory tests too.
tests("t/*.t t/*/*.t");

include('ExtUtils::AutoInstall');
auto_install();

auto_provides();
WriteAll( sign => 0 );

$::VERSION = $required_svn;
die << "." unless eval {require SVN::Core; SVN::Core->VERSION >= main->VERSION };
===> Warning: SVN::Core missing or outdated.
Please manually install SVN::Core by compiling Subversion
(version $required_svn or above) with SWIG/Perl bindings,
and try this installation process again.
.
