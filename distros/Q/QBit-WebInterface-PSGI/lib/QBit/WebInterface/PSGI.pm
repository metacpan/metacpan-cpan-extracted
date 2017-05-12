package QBit::WebInterface::PSGI;
$QBit::WebInterface::PSGI::VERSION = '0.003';
use qbit;

use base qw(QBit::WebInterface);

use QBit::WebInterface::PSGI::Request;

use URI::Escape qw(uri_escape_utf8);

my %RESPONSE_TEXT = (
    200 => 'OK',
    201 => 'CREATED',
    202 => 'Accepted',
    203 => 'Partial Information',
    204 => 'No Response',
    301 => 'Moved',
    302 => 'Found',
    303 => 'Method',
    304 => 'Not Modified',
    400 => 'Bad request',
    401 => 'Unauthorized',
    402 => 'PaymentRequired',
    403 => 'Forbidden',
    404 => 'Not found',
    500 => 'Internal Error',
    501 => 'Not implemented',
    502 => 'Service temporarily overloaded',
    503 => 'Gateway timeout',
);

sub run {
    my ($self) = @_;
    
    $self = $self->new() unless blessed($self);

    return sub {
        my ($env) = @_;
        
        $self->request(QBit::WebInterface::PSGI::Request->new(ENV => $env));

        $self->build_response();
        
        my $data_ref = \$self->response->data;
        if (defined($data_ref)) {
            $data_ref = $$data_ref if ref($$data_ref);
            utf8::encode($$data_ref) if defined($$data_ref) && utf8::is_utf8($$data_ref);
        }
        $data_ref = \'' unless defined($$data_ref);
        
        my $status = $self->response->status || 200;
        
        my @headers = ();
        my @data = ();
        
        push(@headers, 'Status' => $status . (exists($RESPONSE_TEXT{$status}) ? " $RESPONSE_TEXT{$status}" : ''));
        
        push(@headers, 'Set-Cookie' => $_->as_string()) foreach values(%{$self->response->cookies});
        
        while (my ($key, $value) = each(%{$self->response->headers})) {
            push(@headers, $key => $value);
        }
        
        if (!$self->response->status || $self->response->status == 200) {
            push(@headers, 'Content-Type' => $self->response->content_type);

            my $filename = $self->response->filename;
            if (defined($filename)) {
                utf8::encode($filename) if utf8::is_utf8($filename);
                
                push(@headers, 'Content-Disposition' => 'attachment; filename="' . $self->_escape_filename($filename) . '"');
            }
            
            push(@data, $$data_ref);
        } elsif ($self->response->status == 301 || $self->response->status == 302) {
            push(@headers, 'Location' => $self->response->location);
        }

        return [
            $status, \@headers, \@data
          ];
    };
}

sub get_cmd {
    my ($self) = @_;

    my ($path, $cmd);
    if ($self->request->uri() =~ /^\/([^?\/]+)(?:\/([^\/?#]+))?/) {
        ($path, $cmd) = ($1, $2);
    } else {
        ($path, $cmd) = $self->default_cmd();
    }

    $path = '' unless defined($path);
    $cmd  = '' unless defined($cmd);

    return ($path, $cmd);
}

sub make_cmd {
    my ($self, $new_cmd, $new_path, @params) = @_;

    my %vars = defined($params[0])
      && ref($params[0]) eq 'HASH' ? %{$params[0]} : @params;

    my ($path, $cmd) = $self->get_cmd();

    $path = uri_escape_utf8($self->_get_new_path($new_path, $path));
    $cmd = uri_escape_utf8($self->_get_new_cmd($new_cmd, $cmd));

    return "/$path/$cmd"
      . (
        %vars
        ? '?'
          . join(
            $self->get_option('link_param_separator', '&amp;'),
            map {uri_escape_utf8($_) . '=' . uri_escape_utf8($vars{$_})} keys(%vars)
          )
        : ''
      );
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface::PSGI - Package for connect WebInterface with PSGI.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface-PSGI

=head1 Install

=over

=item *

cpanm QBit::WebInterface::PSGI

=item *

apt-get install libqbit-webinterface-psgi-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
