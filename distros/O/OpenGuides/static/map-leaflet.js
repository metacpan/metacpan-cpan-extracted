var full_cgi_url, centre_lat, centre_long, min_lat, min_long, max_lat, max_long, map, map_div_id;
var positions = [], markers = [];

var gicon = L.Icon.extend( {
    options: {
      iconUrl: 'https://maps.google.com/mapfiles/ms/micons/red-dot.png',
      shadowUrl: null,
      iconSize: new L.Point( 32, 32 ),
      iconAnchor: new L.Point( 15, 32 ),
      popupAnchor: new L.Point( 0, -30 )
    }
} );

$(
  function() {
    if ( map_div_id && centre_lat && centre_long ) {
      var map_centre = new L.LatLng( centre_lat, centre_long );

      var osm_layer = new L.TileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' );

      map = new L.Map( map_div_id, {
        center: map_centre,
        layers: [ osm_layer ],
      } );

      if ( !min_lat ) {
        map.setView( map_centre, 13 );
      } else if ( min_lat == max_lat && min_long == max_long) {
        map.setView( new L.LatLng( min_lat, min_long ), 18 );
      } else {
        var bounds = new L.LatLngBounds( new L.LatLng( min_lat, min_long ),
                                         new L.LatLng( max_lat, max_long ) );
        map.fitBounds( bounds );
      }

      L.control.scale().addTo(map);

      add_markers();
    }
  }
);

function add_marker( i, node ) {
  var content, marker, position;

  // This should have already been checked, but no harm in checking again.
  if ( !node.lat || !node.long ) {
    return;
  }

  position = new L.LatLng( node.lat, node.long );

  marker = new L.Marker( position, { icon: new gicon() } );
  map.addLayer( marker );

  content = '<a href="' + full_cgi_url + '?' + node.param + '">' + node.name + '</a>';
  if ( node.address ) {
    content += '<br />' + node.address;
  }
  marker.bindPopup( content );

  markers[ i ] = marker;
  positions[ i ] = position;
}

function show_marker( i ) {
  markers[ i ].openPopup();
  map.panTo( positions[ i ] );
  return false;
}
