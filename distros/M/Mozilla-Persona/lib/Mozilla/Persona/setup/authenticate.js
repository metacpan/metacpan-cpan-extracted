jQuery(function($) {
    var email;
    
    navigator.id.beginAuthentication(function(email_) {
        email = email_;
        $('#email').val(email);
    });

    var onAuthentication = function() {
        var password = $('#password').val();
        $.ajax({
            type: 'POST',
            url: '/persona/index.pl?action=login',
            dataType: 'json',
            data: { email: email, password: password },
            success: function(sig, status, xhr) {
                console.log("Login successful!");
                navigator.id.completeAuthentication();
            },
            error: function(reason, status, xhr) {
                navigator.id.raiseAuthenticationFailure(reason.responseText);
            }
        });
	return false;
    };

    var onCancel = function() {
        navigator.id.cancelAuthentication();
    };

    $('#auth-form').submit(onAuthentication);
    $('.cancel').click(onCancel);
});
