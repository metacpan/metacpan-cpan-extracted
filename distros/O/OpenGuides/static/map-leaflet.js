var centre_lat, centre_long, min_lat, min_long, max_lat, max_long, map, map_div_id;
var positions = [], markers = [];

var gicon = L.Icon.extend( {
    options: {
      iconUrl: 'http://maps.google.com/mapfiles/ms/micons/red-dot.png',
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

      var mq_url = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png';
      var subdomains = [ 'otile1', 'otile2', 'otile3', 'otile4' ];
      var attrib = 'Data, imagery and map information provided by <a href="http://open.mapquest.co.uk" target="_blank">MapQuest</a>, <a href="http://www.openstreetmap.org/" target="_blank">OpenStreetMap</a> and contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/" target="_blank">CC-BY-SA</a>';
      var mapquest_layer = new L.TileLayer( mq_url, { maxZoom: 18, attribution: attrib, subdomains: subdomains } );

      var osm_layer = new L.TileLayer(
          'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' );

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

      var layersControl = new L.Control.Layers( {
        "MapQuest": mapquest_layer,
        "OpenStreetMap": osm_layer,
      } );
      map.addControl( layersControl );

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

  content = '<a href="?' + node.param + '">' + node.name + '</a>';
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
