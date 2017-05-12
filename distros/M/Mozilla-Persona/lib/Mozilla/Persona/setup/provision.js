var sign;

jQuery(function($) {
    // NB.  By browsing secondary server source code, I have
    // discovered that 'user is not authenticated as target user' is
    // the only acceptable error message here.
    //
    // See: static/shared/user.js, primaryUserAuthenticationInfo
    var ifLoggedIn = function(email, thunk) {
        $.ajax({
            type: 'POST',
            crossDomain: true,
            url: '/persona/index.pl?action=is_logged_in',
            dataType: 'json',
            data: { email: email },
            success: function(data, status, xhr) {
                console.log('Logged in: ' + data.logged_in_p);
                if (data.logged_in_p === 0) {
                    console.log('* Not logged in.');
                    return navigator.id.raiseProvisioningFailure('user is not authenticated as target user');
                } else {
                    thunk();
                }
            },
            error: function(data, status, xhr) {
                console.log('Logged in: no.');
                return navigator.id.raiseProvisioningFailure('user is not authenticated as target user');
            }
        });
    };

    sign = function(email, pubkey, cert_duration) {
        console.log('email: '    + email);
        console.log('pubkey: '); console.log(pubkey);
        console.log('duration: ' + cert_duration);
        $.ajax({
            type: 'POST',
            crossDomain: true,
            url: '/persona/index.pl?action=sign',
            dataType: 'json',
            data: { email: email, pubkey: JSON.stringify(pubkey), duration: cert_duration },
            success: function(data, status, xhr) {
		console.log('Success!');
                console.log(data);
                navigator.id.registerCertificate(data.signature);
            },
            error: function(data, status, xhr) {
                return navigator.id.raiseProvisioningFailure(data.responseText);
            }
        });
    };

    navigator.id.beginProvisioning(function(email, cert_duration) {
        console.log('email: ' + email);
        console.log('cert_duration: ' + cert_duration);
        ifLoggedIn(email, function() {
            navigator.id.genKeyPair(function(pubkey) {
                if (typeof(pubkey) === 'string') {
                    pubkey = JSON.parse(pubkey);
                }
                sign(email, pubkey, cert_duration);
            });
        });
    });
});
