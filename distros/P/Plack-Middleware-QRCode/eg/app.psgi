
use lib 'lib';
use Plack::Builder;

warn "Get something like http://localhost:5000/qrcode/adjust?s=5&m=10 to see QRCode Image.";

builder {
    mount '/qrcode' => builder {
        enable 'QRCode';
    }
};
