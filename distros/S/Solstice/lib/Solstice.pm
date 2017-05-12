package Solstice;

# $Id: Model.pm 2393 2005-07-18 17:12:40Z pmichaud $

=head1 NAME

Solstice - Solstice is a Web application development framework for Perl. Based on the MVC programming paradigm, it provides a sensible layout for Web applications that helps you write applications faster and with fewer mistakes.

=head1 SYNOPSIS

  my $lang_service = $solstice_subclass->getLangService();
  my $button_service = $solstice_subclass->getButtonService();
  my $message_service = $solstice_subclass->getMessageService();
  my $config_service = $solstice_subclass->getConfigService();
  my $preference_service = $solstice_subclass->getPreferenceService();
  $solstice_subclass->log($log_message);

=head1 DESCRIPTION

Solstice is a Web application development framework for Perl. Based on the MVC programming paradigm, it provides a sensible layout for Web applications that helps you write applications faster and with fewer mistakes.

For more information, see http://solstice.eplt.washington.edu.

This is a virtual class whose sole job is to provide a common platform of functionality for the various parts of the Solstice framework.  While this can be subclassed directly, you probably want to subclass from something more directly useful, like L<Solstice::Model>, L<Solstice::View>, or L<Solstice::Controller>.

=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::Service::Debug;
use Solstice::ConfigService;
use Solstice::ButtonService;
use Solstice::LogService;
use Solstice::MessageService;
use Solstice::LangService;
use Solstice::PreferenceService;
use Solstice::UserService;
use Solstice::IconService;
use Solstice::HelpService;
use Solstice::IncludeService;
use Solstice::OnloadService;
use Solstice::Service::TempFile;
use Solstice::JavaScriptService;
use Solstice::ContentTypeService;
use Solstice::StringLibrary qw(urlclean);

use UNIVERSAL qw(isa);
use Carp;
use File::Path;

use constant TRUE => 1;
use constant FALSE => 0;
our %service_cache;

our ($VERSION) = ('$Revision: 1440 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods 

=over 4

=item new()

=cut

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    #we must not ask about development mode if we are a config object - deep recursion
    if( 
        ((ref $self) !~ /^Solstice::Configure|Solstice::ConfigService|Solstice::Model::Config::.*$/) && 
        $self->getConfigService()->getDevelopmentMode()
    ){
        $self->{'_caller'} = Carp::shortmess();
    }
    return $self;
}

=item loadModule( $package_name_or_filename )

Dynamically loads the given module.

=cut

sub loadModule {
    my $self = shift;
    my $package = shift;

    my $module = ref($package) || $package;

    #   return TRUE unless $module;
    croak("Cannot load empty module, called from " . join(" ", caller)) unless $module;
    unless( $module =~ /\/|\.pm/ ){ #filename
        $module =~ s/::/\//g;
        $module .= '.pm';
    }

    eval {require $module};
    croak("Could not dynamically load requested module: $@") if $@;

    return TRUE;
}


=item log(\%params)

Log a message to a specified log file. Wrapper around Solstice::LogService

=cut

sub log {
    my $self = shift;
    ref($self) =~ m/^(\w+):.*$/;
    return $self->getLogService($1)->log(@_);
}

=item warn($msg)

Print a message on STDERR, along with information about the caller

=cut

sub warn {
    my $self = shift;
    my $msg  = shift;
    CORE::warn $msg . Carp::shortmess . "\n";
}


=item debug($tag, $mesg)

=cut

sub debug {
    my ($self, $tag, $mesg) = @_;
    my ($package, $file, $line) = caller();

    return Solstice::Service::Debug->new()->debug($tag, $mesg, $package, $line);
}

=item getBaseURL {

=cut

sub getBaseURL {
    my $self = shift;

    my $config      = $self->getConfigService();

    my $use_ssl     = $config->getRequireSSL();
    my $host_name   = $config->get('host_name');
    my $server_port = $config->get('port_number');
    my $base_url    = $config->getURL();

    if ($use_ssl && $server_port && (443 == $server_port)) {
        $server_port = '';
    }
    if (!$use_ssl && $server_port && (80 == $server_port)) {
        $server_port = '';
    }

    my $url = $host_name .
        ($server_port ? ':'.$server_port : '') . '/' .
        $base_url .'/';

    $url =~ s/\/+/\//g;

    $url = 'http' .
        ($use_ssl ? 's' : '') .
        '://' . $url;

    return $url;
}

=item getServerURL()

=cut

sub getServerURL {
    my $self = shift;

    my $config      = $self->getConfigService();

    my $use_ssl     = $config->getRequireSSL();
    my $host_name   = $config->get('host_name');
    my $server_port = $config->get('port_number');

    if ($use_ssl && $server_port && (443 == $server_port)) {
        $server_port = '';
    }
    if (!$use_ssl && $server_port && (80 == $server_port)) {
        $server_port = '';
    }

    my $url = $host_name .
        ($server_port ? ':'.$server_port : '') . '/';

    $url =~ s/\/+/\//g;

    $url = 'http' .
        ($use_ssl ? 's' : '') .
        '://' . $url;

    return $url;

}

=item getAppBaseURL($namespace)

Returns the url for the application of the given namespace.

=cut

sub getAppBaseURL {
    my $self = shift;
    my $namespace = shift;

    my $config = $self->getConfigService($namespace);

    return $self->makeURL($self->getBaseURL(), $config->getAppURL());
}

=item getAppRestURL($namespace)

Returns the root of the applications REST web services

=cut

sub getAppRestURL {
    my $self = shift;
    my $namespace = shift;

    my $config = $self->getConfigService($namespace);
    my $rest_path = $config->getWebServiceRestRoot();

    if (!$rest_path) {
        return;
    }

    return $self->makeURL($self->getBaseURL(), $rest_path, $config->getAppURL());
}

=item getConfigService()

=cut

sub getConfigService {
    my $self = shift;
    my $namespace = shift;
    my $namespace_key = (defined $namespace) ? $namespace : 'solstice';

    unless (defined $service_cache{'configure'}->{$namespace_key}) {
        $service_cache{'configure'}->{$namespace_key} = Solstice::ConfigService->new($namespace);
    }
    return $service_cache{'configure'}->{$namespace_key};
}

=item getTemporaryFileService()

=cut

sub getTempFileService {
    my $self = shift;
    my $namespace = shift;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    unless(defined $service_cache{'temp_files'}->{$namespace}){
        $service_cache{'temp_files'}->{$namespace} = Solstice::Service::TempFile->new($namespace);
    }
    $service_cache{'temp_files'}->{$namespace};
}
=item getButtonService()

=cut

sub getButtonService {
    my $self = shift;
    my $namespace = shift;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    
    unless (defined $service_cache{'button_service'}->{$namespace}) {
        $service_cache{'button_service'}->{$namespace} = Solstice::ButtonService->new($namespace);
    }
    return $service_cache{'button_service'}->{$namespace};
}

=item getLogService()

=cut

sub getLogService {
    my $self = shift;
    my $namespace = shift;

    unless (defined $namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    unless (defined $service_cache{'log_service'}->{$namespace}) {
        $service_cache{'log_service'}->{$namespace} = Solstice::LogService->new($namespace);
    }
    return $service_cache{'log_service'}->{$namespace};
}

=item getMessageService()

=cut

sub getMessageService {
    my $self = shift;
    
    unless (defined $service_cache{'message_service'}) {
        $service_cache{'message_service'} = Solstice::MessageService->new();
    }
    return $service_cache{'message_service'};
}

=item getJavascriptService()

=cut

sub getJavascriptService {
    my $self = shift;

    unless (defined $service_cache{'javascript_service'}) {
        $service_cache{'javascript_service'} = Solstice::JavaScriptService->new();
    }
    return $service_cache{'javascript_service'};
}

=item getContentTypeService()

=cut

sub getContentTypeService {
    my $self = shift;

    unless (defined $service_cache{'content_type_service'}) {
        $service_cache{'content_type_service'} = Solstice::ContentTypeService->new();
    }
    return $service_cache{'content_type_service'};
}

=item makeURL($proto, $host, $dir, $2nd_dir, [$args hashref] )

=cut

sub makeURL {
    my $self = shift;
    my @parts = @_;
    my $args;
    $args = pop @parts if ref $parts[$#parts] eq 'HASH';
    my $proto = shift @parts;

    #is it really a separate protocol, or is that included in the first part?
    if($proto =~ /^\w+:\/\/.+/){
        my $first_part;
        ($proto, $first_part) = split(/:\/\//, $proto);
            unshift @parts, $first_part;
    }


    my $url = join('/', @parts);
    $url =~ s/^\/+//;
    $url = urlclean($url);
    $url = "$proto://$url";

    if ($args) {
        $url .= '?';
        for my $key ( keys %$args ) {
            $url .= "$key=" . $args->{$key} . "&";
        }
        $url =~ s/&$/ /;
    }

    return $url;
}

=item getLangService()

=cut

sub getLangService {
    my $self = shift;
    my $namespace = shift;
    
    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    unless (defined $service_cache{'lang_service'}->{$namespace}) {
        $service_cache{'lang_service'}->{$namespace} = Solstice::LangService->new($namespace);
    }
    return $service_cache{'lang_service'}->{$namespace};
}

=item getPreferenceService()

=cut

sub getPreferenceService {
    my $self = shift;
    my $namespace = shift;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    unless (defined $service_cache{'preference_service'}->{$namespace}) {
        $service_cache{'preference_service'}->{$namespace} = Solstice::PreferenceService->new($namespace);
    }
    return $service_cache{'preference_service'}->{$namespace};    
}

=item getUserService()

=cut

sub getUserService {
    my $self = shift;

    unless (defined $service_cache{'user_service'}) {
        $service_cache{'user_service'} = Solstice::UserService->new();
    }
    return $service_cache{'user_service'};
}

=item getNavigationService()

=cut

sub getNavigationService {
    my $self = shift;
    
    unless (defined $service_cache{'navigation_service'}) {
        $service_cache{'navigation_service'} = Solstice::NavigationService->new();
    }
    return $service_cache{'navigation_service'};
}

=item getOnloadService()
 
=cut 

sub getOnloadService {
    my $self = shift;
    
    unless (defined $service_cache{'onload_service'}) {
        $service_cache{'onload_service'} = Solstice::OnloadService->new();
    }
    return $service_cache{'onload_service'};
}

=item getIncludeService()

=cut

sub getIncludeService {
    my $self = shift;
    return Solstice::IncludeService->new(@_);
}

=item getIconService()

=cut

sub getIconService {
    my $self = shift;
    return Solstice::IconService->new(@_);
}

=item getHelpService()

=cut

sub getHelpService {
    my $self = shift;
    return Solstice::HelpService->new(@_);
}

=back


=head2 Attribute Validation Methods

=over 4

=item isValidInteger($str)

=cut

sub isValidInteger {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    return ($str =~ /^[-]?[0-9]+$/) ? TRUE : FALSE;
}

=item isValidPositiveInteger($str)

=cut

sub isValidPositiveInteger {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    return ($str =~ /^[0-9]+$/ and $str != 0) ? TRUE : FALSE;
}

=item isValidNonNegativeInteger($str)

=cut

sub isValidNonNegativeInteger {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    return ($str =~ /^[0-9]+$/) ? TRUE : FALSE;
}

=item isValidNumber($str)

=cut

sub isValidNumber {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    return ($str =~ /^[-]?([0-9]*\.[0-9]+|[0-9]+)$/) ? TRUE : FALSE;
}

=item isValidPositiveNumber($str)

=cut

sub isValidPositiveNumber {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    return ($str =~ /^([0-9]*\.[0-9]+|[0-9]+)$/) ? TRUE : FALSE;
}
=item isValidString($str)

=cut

sub isValidString {
    my $self = shift;
    my $str = shift;
    return FALSE if (scalar @_);
    return TRUE if (!defined $str);
    return FALSE if (ref $str);
    return FALSE if (ref \$str eq 'GLOB');
    return TRUE;
}

=item isValidEmail($str)

=cut

sub isValidEmail {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);

    #Mail::RFC822::Address was too lax for us and our users, so we 
    #implemented our own sanity test

    return (
        # Dot sanity
        $str !~ /\.{2,}/ && $str !~ /^\./ && 
        
        # Looks like an email?
        lc($str) =~ /^[\w\-\+\.]+\@[a-z0-9\-]*\.[a-z0-9\-\.]+$/
    ) ? TRUE : FALSE;
}

=item isValidURL($str)

=cut

sub isValidURL {
    my $self = shift;
    my $str = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    # This should get smarter (or be replaced with a CPAN module).
    # Doesn't currently do any validation after the ://, it just makes 
    # sure there is at least one character, which is obviously not 
    # too satisfactory.
    return FALSE unless $str =~ m'^(http|ftp|https)://[\w]+';
    return TRUE;
}

=item isValidBoolean($str)

=cut

sub isValidBoolean {
    my $self = shift;
    my $str  = shift;
    return FALSE unless isValidString(undef, $str, @_);
    return TRUE if (!defined $str);
    return ($str =~ /^(0|1)$/) ? TRUE : FALSE;
}

=item isValidObject($obj, $class)

=cut

sub isValidObject {
    my $self = shift;
    my ($obj, $class) = @_;
    return TRUE if (! defined $obj);
    return isa($obj, $class) ? TRUE : FALSE;
}

=item isValidDateTime($obj)

=cut

sub isValidDateTime {
    my $self = shift;
    my $obj  = shift;
    return TRUE if (!defined $obj);
    return isa($obj, 'Solstice::DateTime') ? ($obj->isValid() || $obj->isEmpty) : FALSE;
}

=item isValidPerson($obj)

=cut

sub isValidPerson {
    my $self = shift;
    my $obj  = shift;
    return TRUE if (!defined $obj);
    return isa($obj, 'Solstice::Person') ? TRUE : FALSE;
}

=item isValidGroup($obj)

=cut

sub isValidGroup {
    my $self = shift;
    my $obj  = shift;
    return TRUE if (!defined $obj);
    return isa($obj, 'Solstice::Group') ? TRUE : FALSE;
}

=item isValidList($obj)

=cut

sub isValidList {
    my $self = shift;
    my $obj  = shift;
    return TRUE if (!defined $obj);
    return isa($obj, 'Solstice::List') ? TRUE : FALSE;
}

=item isValidTree($obj)

=cut

sub isValidTree {
    my $self = shift;
    my $obj  = shift;
    return TRUE if (!defined $obj);
    return isa($obj, 'Solstice::Tree') ? TRUE : FALSE;
}

=item isValidArrayRef($ref)

=cut

sub isValidArrayRef {
    my $self = shift;
    my $ref  = shift;
    return TRUE if (!defined $ref);
    return UNIVERSAL::isa($ref, 'ARRAY') ? TRUE : FALSE;
}

=item isValidHashRef($ref)

=cut

sub isValidHashRef {
    my $self = shift;
    my $ref  = shift;
    return TRUE if (!defined $ref);
    return (ref($ref) eq 'HASH') ? TRUE : FALSE;
}

# These aliases are just here for historical sake

*isValidFloat = *isValidNumber;
*_isValidInteger = *isValidInteger;
*_isValidPositiveInteger = *isValidPositiveInteger;
*_isValidNonNegativeInteger = *isValidNonNegativeInteger;
*_isValidNumber = *isValidNumber;
*_isValidPositiveNumber = *isValidPositiveNumber;
*_isValidString = *isValidString;
*_isValidEmail = *isValidEmail;
*_isValidURL = *isValidURL;
*_isValidBoolean = *isValidBoolean;
*_isValidObject = *isValidObject;
*_isValidDateTime = *isValidDateTime;
*_isValidPerson = *isValidPerson;
*_isValidGroup = *isValidGroup;
*_isValidList = *isValidList;
*_isValidTree = *isValidTree;
*_isValidArrayRef = *isValidArrayRef;
*_isValidHashRef = *isValidHashRef;

=back

=head2 Private Convenience Methods

=over 4

=cut

=item _dirCheck($dir)

Creates the passed directory and dies if this isn't possible

=cut

sub _dirCheck {
    my $self = shift;
    my $file_path = shift;

    unless (-d $file_path ){
        mkpath($file_path) or die "Cannot create directory $file_path - called from ". join(' ', caller())."\n";
    }

    unless( -w $file_path ){
        die "Cannot write to directory $file_path - called from ". join(' ', caller()). "\n";

    }
}

#sub DESTROY {
#    my $self = shift;
#    if($self->getConfigService()->getDevelopmentMode() && $self->{"_caller"}){
#        my $orig_error = undef;;
#        if($@){ $orig_error = $@; }
#        eval { die }; 
#        CORE::warn("Leaked ". ref($self) ." freed at process destruction! Created".$self->{'_caller'}) if $@ =~ /global destruction/;
#        $@ = $orig_error;
#    }
#}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>,
L<Solstice::LogService|Solstice::LogService>,
L<Solstice::UserService|Solstice::UserService>,
L<Solstice::ValidationParam|Solstice::ValidationParam>,
L<Solstice::CGI|Solstice::CGI>,
L<Data::FormValidator|Data::FormValidator>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: 1410 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
