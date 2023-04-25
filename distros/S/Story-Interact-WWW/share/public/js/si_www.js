( function($) {

	var state;
	var current_page;

	function render_page ( page ) {
		$( "#next_pages" ).html( "" );
		$( "#html" ).html( page.html );
		for ( var link of page.next_pages ) {
			let link_id = link[0];
			let link_desc = link[1];
			let link_classes = 'list-group-item-primary';
			if ( link[2].css_class == 'success' ) { link_classes = 'list-group-item-success'; }
			if ( link[2].css_class == 'danger' )  { link_classes = 'list-group-item-danger';  }
			if ( link[2].css_class == 'warning' ) { link_classes = 'list-group-item-warning'; }
			if ( link[2].css_class == 'info' )    { link_classes = 'list-group-item-info';    }
			$( "#next_pages" ).append(
				'<button class="list-group-item list-group-item-action ' + link_classes + '" x-data-page-id="' +
				link_id +
				'">' +
				link_desc +
				'</button>'
			);
		}
		state = page.state;
		current_page = page;
		after_render_page( page );
	}

	function get_page ( page_id ) {
		$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/page/' + encodeURIComponent(page_id), {
			method: 'POST',
			data: JSON.stringify( { "state": state } ),
			contentType: 'application/json',
			success: render_page,
			dataType: 'json',
		} );
	}

	// Load initial state...
	$( function () {
		$.get( API + '/state/init', {}, function ( data ) {
			state = data.state;
			get_page( 'main' );
		}, 'json' );
	} );

	// Make page links work...
	$( "#next_pages" ).on( "click", "button", function ( e ) {
		let page_id = $( this ).attr( "x-data-page-id" );
		get_page( page_id );
	} );

	// Save button
	$( "#save" ).on( "click", function ( e ) {
		let d = Date.now();
		let label = prompt( "Please enter a label for the bookmark", "Unlabelled" );
		let page = current_page;
		var store = [];
		let got = localStorage.getItem( STORAGE_KEY );
		if ( got ) store = JSON.parse( got );
		store.push( {
			"date": d,
			"label": label,
			"stored_data": page,
		} );
		localStorage.setItem( STORAGE_KEY, JSON.stringify( store ) );
		refresh_saved_games();
	} );

	function refresh_saved_games () {
		var store = [];
		let got = localStorage.getItem( STORAGE_KEY );
		if ( got ) store = JSON.parse( got );
		$( "#saved_games" ).html( "" );
		for (var i = store.length - 1; i >= 0; i--) {
			let g = store[i];
			let d = new Date( g.date );
			$( "#saved_games" ).append(
				'<li class="list-group-item list-group-item-light" x-data-saved-game-ix="' + i + '">' +
				'<div><strong>' + g.label + '</strong></div>' +
				'<div><small>Timestamp: ' + d.toISOString() + '</small></div>' +
				'<div><small><a class="text-secondary saved-game-go" href="#">Go to</a></small> &middot; ' +
				'<small><a class="text-danger saved-game-delete" href="#">Delete</a></small></div>' +
				'</li>'
			);
		}
	}

	$( "#saved_games" ).on( "click", ".saved-game-go", function ( e ) {
		let ix = $( this ).parents( "li" ).attr( "x-data-saved-game-ix" );
		if ( confirm( "Return to bookmark? Any progress you have made since then will be lost." ) ) {
			var store = [];
			let got = localStorage.getItem( STORAGE_KEY );
			if ( got ) store = JSON.parse( got );
			render_page( store[ix].stored_data );
		}
	} );

	$( "#saved_games" ).on( "click", ".saved-game-delete", function ( e ) {
		let ix = $( this ).parents( "li" ).attr( "x-data-saved-game-ix" );
		if ( confirm( "Remove this bookmark?" ) ) {
			var store = [];
			let got = localStorage.getItem( STORAGE_KEY );
			if ( got ) store = JSON.parse( got );
			store.splice( ix, 1 );
			localStorage.setItem( STORAGE_KEY, JSON.stringify( store ) );
			refresh_saved_games();
		}
	} );

	refresh_saved_games();

} )( jQuery );
