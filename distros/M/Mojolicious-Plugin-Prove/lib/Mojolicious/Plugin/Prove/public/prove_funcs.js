function prove( name, testfile, prefix ) {
    var get_url = '/' + prefix + '/test/' + name + '/' + testfile + '/run';
    
    $.ajax({
        type: 'GET',
        url: get_url,
        success: function( data ) {
            if( data.match( /FAIL/ ) ) {
                $('#test').css( 'background-color', 'red' );
                $('#test').html( '<strong>FAIL</strong>' );
            }
            else {
                $('#test').css( 'background-color', 'lightgreen' );
                $('#test').html( '<strong>OK</strong>' );
            }
        }
    });
}