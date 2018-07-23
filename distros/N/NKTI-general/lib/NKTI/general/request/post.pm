package NKTI::general::request::post;

use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common qw{ POST };
use CGI;
use JSON;

# Create Module for Action Request POST :
# ------------------------------------------------------------------------
=head1 MODULE action()

    Parameter Modul :
    ----------------------------------------
    _url_request =>     Parameter yang berisi URL Request.
                        Ex : "http://yourdomain.tld/your_dir/your_file_request.
    _data_post =>       Parameter yang berisi Format array Data yang akan di request.

    Format _data_post :
    ----------------------------------------
    Format : [
        'name_post' => 'value_name_post',
    ]

=cut
sub action {
    # ----------------------------------------------------------------
    # Define parameter subroutine :
    # ----------------------------------------------------------------
    my $class = shift;
    my $self = {
        '_url_request' => shift,
        '_data_post' => shift,
    };
    bless $self, $class;
    # ----------------------------------------------------------------
    # Define LWP User Agent :
    # ----------------------------------------------------------------
    my $ua = LWP::UserAgent->new();
    my $url = $self->{_url_request};
    my $data_post = $self->{_data_post};
    # ----------------------------------------------------------------
    # Declare scalar for placing result :
    # ----------------------------------------------------------------
    my %data;
    # ----------------------------------------------------------------
    # Custom HTTP Request Header and Data Request :
    # ----------------------------------------------------------------
    #    my $req = POST($url, ['plain-text' => 'testing', 'how' => 'perl']);
    my $req = POST($url, $data_post);
    $req->header('X-Requested-With' => 'XMLHttpRequest');
    # ----------------------------------------------------------------
    # Action for Request POST :
    # ----------------------------------------------------------------
    my $resp = $ua->request($req);
    # ----------------------------------------------------------------
    # Check IF $resp->is_success == true :
    # ----------------------------------------------------------------
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        # ----------------------------------------------------------------
        # Placing success result into hash "%data" :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 1,
            'respon' => $message
        }
    }
    # End of check IF $resp->is_success == true.
    # ================================================================

    # Check IF $resp->is_success == false :
    # ----------------------------------------------------------------
    else {
        # ----------------------------------------------------------------
        # Placing error result into hash "%data" :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 0,
            'respon' => {
                'code' => $resp->code,
                'msg' => $resp->message
            }
        }
    }
    # End of check IF $resp->is_success == false.
    # ================================================================

    # Return Data :
    # ----------------------------------------------------------------
    return \%data;
}
# End of Create Module for Action Request POST.
# ===========================================================================================================
1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk melakukan request POST.
=cut