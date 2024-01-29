const $ = jQuery;
let state;
let current_page;
let session;

const sanity_options = {
	allowedTags: [
		"h1", "h2", "h3", "h4", "h5", "h6", "section", "blockquote", "dd", "div",
		"dl", "dt", "hr", "li", "ol", "p", "pre", "ul", "abbr", "b", "br", "cite",
		"code", "dfn", "em", "i", "kbd", "mark", "q", "s", "samp", "small", "span",
		"strong", "sub", "sup", "time", "u", "var", "wbr",
		"a",
	],
	allowedAttributes: {
		'*': [ 'class', 'data-*' ],
		'a': [ 'href', 'target', 'class' ],
	},
	allowedClasses: {
		'*': false,
	},
};

function shtml ( dirty ) {
	return sanitizeHtml( dirty, sanity_options );
}

function esc_html ( dirty ) {
	if ( dirty === undefined ) {
		return '';
	}
	dirty = dirty + "";
	return dirty.replaceAll( '&', '&amp;' ).replaceAll( '<', '&lt;' ).replaceAll( '>', '&gt;' ).replaceAll( '"', '&quot;' ).replaceAll( "'", '&#039;' );
}

function page_ok () {
	$( document.body ).removeClass( 'loading' ).removeClass( 'failed' );
}

function page_loading () {
	$( document.body ).removeClass( 'failed' ).addClass( 'loading' );
}

function page_failed () {
	$( document.body ).removeClass( 'loading' ).addClass( 'failed' );
}

function render_page ( page ) {
	if ( session ) {
		$( "#save_server" ).removeClass( "d-none" );
	}
	else {
		$( "#save_server" ).addClass( "d-none" );
	}
	
	if ( !page.next_pages || page.next_pages.length==0 ) {
		alert( 'No further pages!' );
		page_failed();
		return false;
	}
	$( "#next_pages" ).html( "" );
	$( "#html" ).html( shtml( page.html ) );
	for ( let link of page.next_pages ) {
		let link_id = link[0];
		let link_desc = link[1];
		let link_classes = 'text-primary';
		let style = '';
		if ( link[2].css_class == 'success' ) { link_classes = 'text-success'; }
		if ( link[2].css_class == 'danger' )  { link_classes = 'text-danger';  }
		if ( link[2].css_class == 'warning' ) { link_classes = 'text-warning'; }
		if ( link[2].css_class == 'info' )    { link_classes = 'text-info';    }
		if ( link[2].colour ) {
			style = style + 'color:' + link[2].colour + ' !important;';
		}
		if ( style.length ) {
			style = ' style="' + style + '"';
		}
		$( "#next_pages" ).append(
			'<div class="my-1"><a href="#" class=" ' + esc_html( link_classes ) + '" x-data-page-id="' + esc_html( link_id ) + '"' + style + '>' + shtml( link_desc ) + '</a></div>'
		);
	}
	state = page.state;
	current_page = page;
	after_render_page( page );
	page_ok();
}

function get_page ( page_id ) {
	let obj = { "state": state };
	if ( session && session.session ) {
		obj.session = session.session;
	}
	page_loading();
	$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/page/' + encodeURIComponent(page_id), {
		method: 'POST',
		data: JSON.stringify( obj ),
		contentType: 'application/json',
		success: render_page,
		dataType: 'json',
		error: function ( xhr, type, str ) {
			let msg = 'Error: ' + type;
			if ( str && str.length ) {
				msg = msg + ' - ' + str;
			}
			alert( msg );
			page_failed();
		},
	} );
}

function set_session ( value ) {
	if ( value && value.session ) {
		session = value;
		$( "#login" ).html( "<p>Logged in as " + esc_html( value.username ) + ". <a href='#' id='logout_button' class='text-danger'>Log out</a>.</p>" );
	}
	else {
		session = null;
		$( "#login" ).html( `
			<h3 class="h5">Log in</h3>
			<form class="row g-2">
				<div class="col-6"><input id="login_username" class="form-control form-control-sm" type="text" placeholder="Username" aria-label="Username" title="Username"></div>
				<div class="col-6"><input id="login_password" class="form-control form-control-sm" type="password" placeholder="Password" aria-label="Password" title="Password"></div>
				<div class="col-6"><button id="login_button" type="button" class="btn btn-sm btn-primary w-100">Log in</button></div>
				<div class="col-6"><button id="signup_button" type="button" class="btn btn-sm btn-secondary w-100">or create user</button></div>
			</form>
			<p><small style="font-size:70%">Logging in is not required, but can enable additional features.</small></p>
		` );
	}
	localforage.setItem( '!session', session );
	refresh_bookmark_list();
}

function refresh_bookmark_list () {
	localforage.getItem( STORAGE_KEY, function ( err, bookmark_storage ) {
		if ( err ) {
			console.log( err );
			alert( "Error reading bookmarks" );
			return;
		}
		if ( ! bookmark_storage ) {
			bookmark_storage = [];
		}
		$( "#client_bookmarks" ).html( "" );
		for (let i = bookmark_storage.length - 1; i >= 0; i--) {
			let g = bookmark_storage[i];
			let d = new Date( g.date );
			$( "#client_bookmarks" ).append(
				'<li class="list-group-item text-bg-dark" data-saved-game-ix="' + i + '">' +
				'<div><strong>' + esc_html( g.label ) + '</strong> <small style="font-size:75%">' + d.toISOString() + '</small></div>' +
				'<div><small><a class="text-primary saved-game-go" href="#">Go here</a></small> &middot; ' +
				'<small><a class="text-success saved-game-save" href="#">Save</a></small> &middot; ' +
				'<small><a class="text-danger saved-game-delete" href="#">Delete</a></small></div>' +
				'</li>'
			);
		}
		if ( SERVER_STORAGE && session ) {
			$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/bookmark', {
				method: 'GET',
				data: { "session": session.session },
				contentType: 'application/json',
				success: function ( d ) {
					$( "#server_bookmarks" ).html( "" );
					for (const b of d.bookmarks) {
						let d = new Date( b.modified * 1000 );
						$( "#server_bookmarks" ).append(
							'<li class="list-group-item text-bg-dark" data-saved-game-slug="' + esc_html( b.slug ) + '">' +
							'<div><strong>' + esc_html( b.label ) + '</strong> <small style="font-size:75%">' + d.toISOString() + '</small></div>' +
							'<div><small><a class="text-primary saved-game-go" href="#">Go here</a></small> &middot; ' +
							'<small><a class="text-success saved-game-save" href="#">Save</a></small> &middot; ' +
							'<small><a class="text-danger saved-game-delete" href="#">Delete</a></small></div>' +
							'<div><small>Server id: <code>' + esc_html( b.slug ) + '</code></small></div>' +
							'</li>'
						);
					}
				},
				dataType: 'json',
			} );
		}
		else {
			$( "#server_bookmarks" ).html( "" );
		}
	} );
}


if ( SERVER_STORAGE ) {
	
	localforage.getItem( '!session', function ( err, value ) {
		if ( err ) { return false; }
		set_session( value );
	} );
	
	$( document.body ).on( 'click', '#login_button', function ( e ) {
		e.preventDefault();
		page_loading();
		$.ajax( API + '/session/init', {
			method: 'POST',
			data: JSON.stringify( {
				"username": $( "#login_username" ).val(),
				"password": $( "#login_password" ).val(),
			} ),
			contentType: 'application/json',
			success: function ( data ) {
				if ( data.error ) { alert( data.error ); page_ok(); }
				else              { set_session( data ); page_failed(); }
			},
			error: function ( xhr, type ) {
				alert( 'Error: ' + type );
				page_failed();
			},
			dataType: 'json',
		} );
	} );

	$( document.body ).on( 'click', '#logout_button', function ( e ) {
		e.preventDefault();
		page_loading();
		$.ajax( API + '/session/destroy', {
			method: 'POST',
			data: JSON.stringify( { "session": session.session } ),
			contentType: 'application/json',
			success: function ( data ) {
				if ( data.error ) { alert( data.error ); page_failed(); }
				else              { set_session( null ); page_ok(); }
			},
			error: function ( xhr, type ) {
				alert( 'Error: ' + type );
				page_failed();
			},
			dataType: 'json',
		} );
	} );

	$( document.body ).on( 'click', '#signup_button', function ( e ) {
		e.preventDefault();

		let username = $( "#login_username" ).val();
		let password = $( "#login_password" ).val();
		if ( username.length < 2 || password.length < 6 ) {
			alert( 'Error: please enter a username (2+ characters) and password (6+ characters) first!' );
			return;
		}

		page_loading();
		$.ajax( API + '/user/init', {
			method: 'POST',
			data: JSON.stringify( {
				"username": username,
				"password": password,
			} ),
			contentType: 'application/json',
			success: function ( data ) {
				if ( data.error ) { alert( data.error ); page_ok(); }
				else              { set_session( data ); page_failed(); }
			},
			error: function ( xhr, type ) {
				alert( 'Error: ' + type );
				page_failed();
			},
			dataType: 'json',
		} );
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
$( "#next_pages" ).on( "click", "a", function ( e ) {
	e.preventDefault();
	let $this = $( this );
	let confirmed = true;
	if ( $this.hasClass( 'text-danger' ) ) {
		confirmed = confirm( 'Sure?' );
	}
	if ( confirmed ) {
		let page_id = $this.attr( "x-data-page-id" );
		get_page( page_id );
	}
} );

// Save (to client) button
$( "#save" ).on( "click", function ( e ) {
	let d = Date.now();
	let label = prompt( "Please enter a label for the bookmark", "Unlabelled" );
	let page = current_page;
	localforage.getItem( STORAGE_KEY, function ( err, bookmark_storage ) {
		if ( err ) {
			console.log( err );
			alert( "Error storing game" );
			return;
		}
		if ( ! bookmark_storage ) {
			bookmark_storage = [];
		}
		bookmark_storage.push( {
			"date": d,
			"label": label,
			"stored_data": page,
		} );
		localforage.setItem( STORAGE_KEY, bookmark_storage, function ( err ) {
			if ( err ) {
				console.log( err );
				alert( "Error storing bookmark" );
				return;
			}
			refresh_bookmark_list();
		} );
	} );
} );

// Save (to server) button
$( "#save_server" ).on( "click", function ( e ) {
	if ( ! SERVER_STORAGE ) {
		return;
	}
	let label = prompt( "Please enter a label for the bookmark", "Unlabelled" );
	let encoded_page = JSON.stringify( current_page );
	page_loading();
	$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/bookmark', {
		method: 'POST',
		data: JSON.stringify( {
			"label": label,
			"stored_data": encoded_page,
			"session": session.session,
		} ),
		contentType: 'application/json',
		success: function ( d ) {
			page_ok();
			refresh_bookmark_list();
		},
		error: function ( xhr, type ) {
			alert( 'Error: ' + type );
			page_failed();
		},
		dataType: 'json',
	} );
} );

// Load saved game button
$( document.body ).on( "click", ".saved-game-go", function ( e ) {
	if ( confirm( "Return to bookmark? Any progress you have made since then will be lost." ) ) {
		let slug = $( this ).parents( "li" ).attr( "data-saved-game-slug" );
		if ( SERVER_STORAGE && slug && session ) {
			page_loading();
			$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/bookmark/' + encodeURIComponent(slug), {
				method: 'GET',
				data: { "session": session.session },
				contentType: 'application/json',
				success: function ( d ) {
					page_ok();
					render_page( JSON.parse( d.stored_data ) );
					$( '#sidebar' ).offcanvas( 'hide' );
				},
				error: function ( xhr, type ) {
					alert( 'Error: ' + type );
					page_failed();
				},
				dataType: 'json',
			} );
		}
		else {
			let ix = $( this ).parents( "li" ).attr( "data-saved-game-ix" );
			localforage.getItem( STORAGE_KEY, function ( err, bookmark_storage ) {
				if ( err ) {
					console.log( err );
					alert( "Error reading bookmarks" );
					return;
				}
				render_page( bookmark_storage[ix].stored_data );
				$( '#sidebar' ).offcanvas( 'hide' );
			} );
		}
	}
} );

// Re-save game button
$( document.body ).on( "click", ".saved-game-save", function ( e ) {
	let page = current_page;
	let slug = $( this ).parents( "li" ).attr( "data-saved-game-slug" );
	if ( confirm( "Replace this bookmark with the current page?" ) ) {
		if ( SERVER_STORAGE && slug && session ) {
			page_loading();
			$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/bookmark/' + encodeURIComponent(slug), {
				method: 'POST',
				data: JSON.stringify( { "session": session.session, "stored_data": JSON.stringify(page) } ),
				contentType: 'application/json',
				success: function ( d ) {
					page_ok();
					refresh_bookmark_list();
				},
				error: function ( xhr, type ) {
					alert( 'Error: ' + type );
					page_failed();
				},
				dataType: 'json',
			} );
		}
		else {
			let ix = $( this ).parents( "li" ).attr( "data-saved-game-ix" );
			localforage.getItem( STORAGE_KEY, function ( err, bookmark_storage ) {
				if ( err ) {
					console.log( err );
					alert( "Error storing bookmark" );
					return;
				}
				bookmark_storage[ix].stored_data = page;
				bookmark_storage[ix].date = Date.now();
				localforage.setItem( STORAGE_KEY, bookmark_storage, function ( err ) {
					if ( err ) {
						console.log( err );
						alert( "Error storing bookmark" );
						return;
					}
					refresh_bookmark_list();
				} );
			} );
		}
	}
} );

// Delete saved game button
$( document.body ).on( "click", ".saved-game-delete", function ( e ) {
	let slug = $( this ).parents( "li" ).attr( "data-saved-game-slug" );
	if ( confirm( "Remove this bookmark?" ) ) {
		if ( SERVER_STORAGE && slug && session ) {
			page_loading();
			$.ajax( API + '/story/' + encodeURIComponent(STORY_ID) + '/bookmark/' + encodeURIComponent(slug), {
				method: 'POST',
				data: JSON.stringify( { "session": session.session } ),
				contentType: 'application/json',
				success: function ( d ) {
					page_ok();
					refresh_bookmark_list();
				},
				error: function ( xhr, type ) {
					alert( 'Error: ' + type );
					page_failed();
				},
				dataType: 'json',
			} );
		}
		else {
			let ix = $( this ).parents( "li" ).attr( "data-saved-game-ix" );
			localforage.getItem( STORAGE_KEY, function ( err, bookmark_storage ) {
				if ( err ) {
					console.log( err );
					alert( "Error deleting stored bookmark" );
					return;
				}
				console.log( bookmark_storage );
				bookmark_storage.splice( ix, 1 );
				console.log( bookmark_storage );
				localforage.setItem( STORAGE_KEY, bookmark_storage, function ( err ) {
					if ( err ) {
						console.log( err );
						alert( "Error deleting stored bookmark" );
						return;
					}
					refresh_bookmark_list();
				} );
			} );
		}
	}
} );

refresh_bookmark_list();
