<?php Class OpenThought {

function OpenThought($args = array()) {

    $this->VERSION = "0.01";
    $this->DEBUG = "0";

    $this->_persist = $args['persist'] || 0;

    $this->_init();

}

function _init() {

    $settings = array(
                        "log_enabled",
                        "log_level",
                        "require",
                        "channel_type",
                        "channel_visible",
                        "channel_url_replace",
                        "selectbox_max_width",
                        "selectbox_trim_string",
                        "selectbox_single_row_mode",
                        "selectbox_multi_row_mode",
                        "checkbox_true_value",
                        "checkbox_false_value",
                        "radio_null_selection_value",
                        "data_mode",
    );

    $this->_response   = array();
    $this->_settings = array();

    foreach ($settings as $setting) {
        $this->_settings[$setting] = array();

    }

}

function output() {
    $save = $serialized_data = $restore = "";

    $settings = array();
    foreach ( array_keys($this->_settings) as $setting ) {
        if (count($this->_settings[$setting])) {
            if (isset($this->_settings[$setting])) {
                $serialized_data .= join('', $this->_settings[$setting] );
                array_push($settings, $setting);
            }

        }
    }

    if(! $this->settings_persist ) {
        $save    .= $this->_settings_save( $settings );
        $restore .= $this->_settings_restore( $settings );
    }

    if (count($this->_response)) {
        $serialized_data .= join('', $this->_response);
    }

    $code = $this->_add_tags("${save}${serialized_data}${restore}");

    $this->DEBUG && error_log($code) ;

    return $code;


}

function param($data, $options = array()) {
    $data = $this->_as_javascript($data);

    $save    = "";
    $restore = "";
    if (count($options)) {
        $save =    $this->_settings_save( array_keys($options) ) .
                   $this->settings($options, 1);
        $restore = $this->_settings_restore( array_keys($options) );
    }

    $data = "${save}parent.OpenThought.ServerResponse(${data});${restore}";

    array_push( $this->_response, $data );

    return $this->_add_tags( $data );
}

function focus($field) {

    $data = " parent.OpenThought.Focus('$field');";

    array_push( $this->_response, $data );

    return $this->_add_tags( $data );
}

function javascript($javascript_code) {

    $data = " with (parent.document) { $javascript_code }";

    array_push( $this->_response, $data );

    return $this->_add_tags( $data );
}

function url($url) {
    $javascript_code="";

    if ( _is_array($url) ) {
        if ( isset($url[0]) ) {
            if ( ! is_scalar($url[0]) ) {
                die("The first element of the arrayref passed into 'url' should be a scalar containing the url.");
            }

            $javascript_code = "parent.OpenThought.FetchHtml('$url[0]'";
        }
        if ( $url[1] ) {
            if (! _is_hash($url[1]) ) {
                die("The second element of the arrayref passed into 'url' is optional, but if supplied, must be a hashref.");
            }
            foreach ( array_keys($url[1]) as $param) {
                if ( isset ($url[1][$param]) ) {
                    $javascript_code .= ",'$param=$url[1][$param]'";
                }
                else {
                    $javascript_code .= ",'$param'";
                }
            }
        }
    }
    elseif (is_scalar($url)) {
        $javascript_code = "parent.OpenThought.FetchHtml('$url'";
    }
    else {
        die("The 'url' method takes either a scalar containing the url, or an an arrayref containing both the url and a hashref with url parameters.");
    }

    $javascript_code .= ");";

    array_push($this->_response, $javascript_code);

    return $this->_add_tags($javascript_code);

}

function settings($settings, $return_only=0) {

    if (! _is_hash($settings) ) {
        die( "When you pass in settings, they need to be a hash " .
             '.  Either $OT->settings( $settings ) or ' .
             '$OT->response( settings => $settings ).' );
    }

    $data = "";
    foreach ( array_keys($settings) as $name ) {
        # Persist is special as well.  It defines whether the settings
        # being sent are to remain as such throughout the life of the
        # application, or just for this current request.
        if( $name == "settings_persist" ) {
            $this->settings_persist = $settings[$name];
        }

        # All other parameters are treated the same here
        elseif ( $this->_settings[$name] ) {
            $setting = "parent.OpenThought.config.$name = \"" .
                        $this->_escape_javascript( $settings[$name] ) .  "\";";

            if (! $return_only) {
                array_push($this->_settings[$name], $setting);
            }

            $data .= $setting;

        }
        else {
            error_log("No such setting [$name].");
        }
    }
    if ($return_only) {
        return $data;
    }
    else {
        return $this->_add_tags($data);
    }

}

function response($params = array()) {
    foreach ( array_keys($params) as $param ) {
        $this->$param( $params[$param] );
    }

    return $this->output();

}

function _settings_save($settings) {

    $data = "";

    foreach ($settings as $setting) {
        $data .= " var __$setting=parent.OpenThought.config.$setting;";
    }

    return $data;
}

function _settings_restore($settings) {
    $data = "";

    foreach ($settings as $setting) {
        $data .= " parent.OpenThought.config.$setting = __$setting;";
    }

    return $data;
}

function _as_javascript($data) {
    $packet = "{";

    while ( list( $key, $val ) = each($data) ) {

        # In the case of a simple key=value assignment, do the following.  This
        # is used for text, password, textbox, uniquely named checkboxes, and
        # radio buttons
        # Convert: $hash[key] = "value"
        # To:      key : value,
        if( is_scalar($val) ) {
            if ( isset($val) ) {
                $val = $this->_escape_javascript( $val );
                $packet .= "\"$key\": \"$val\",";
            }
            else {
                $packet .= "\"$key\": null,";
            }
        }

        # In the case of adding one item to a select box, or clearing a select box
        # Convert: $hash[key] = array( $val1, $val2 )
        # To:      key: [ val1, val2 ],
        elseif ( $this->_is_array($val) and !is_array($val[0]) ) {

            # If we are sent something like:
            #   $field->{'selectbox_name'} = [ "" ];
            # That means we wish to clear the selectbox
            if ( $val[0] == "" ) {

                $packet .= "\"$key\": [ \"\" ],";
            }
            else {

                $packet .= "\"$key\": [ ";
                foreach ($val as $my_val) {
                    $packet .= '"' .
                        ($this->_escape_javascript($my_val) || "") . '",';
                }

                $packet = substr($packet, 0, -1);
                $packet .= " ],";
            }
        }

        # For updating select lists using an array of hashes
        # Convert: $hash[key] = array( array( val1 => val2 ), array( val3 => val4 ) )
        # To:      key: [ { val1: val2 }, { val3: val4 } ],
        elseif ( $this->_is_array($val) and $this->_is_hash($val[0]) ) {
            $packet .= "\"$key\": [ ";

            foreach ( $val as $hash ) {
                while ( list( $key1, $val1 ) = each($hash) ) {
                    $val1 = $this->_escape_javascript( $val1 );
                    $packet .= "{\"$key1\": \"$val1\"},";
                }
            }

            $packet = substr($packet, 0, -1);
            $packet .= " ],";
        }

        # This is done for adding multiple items to select boxes
        # Convert: $hash[key] = array( array( val1, val2 ), array( val3, val4 ) )
        # To:      key: [ [ val1, val2 ], [ val3, val4 ] ],
        elseif ( $this->_is_array($val) and $this->_is_array($val[0]) ) {
            $packet .= "\"$key\": [ ";
            $i=0;
            foreach ( $val as $array ) {

                # If we are only sent text for the selectlist, and no value --
                # define the value as empty.  When it gets to the browser, the
                # value will be made the same as the text
                if (!isset($array[1])) {
                    $array[1] = "";
                }

                $array[0] = $this->_escape_javascript( $array[0] );
                $array[1] = $this->_escape_javascript( $array[1] );
                $packet .= "[\"$array[0]\",\"$array[1]\"],";
                $i++;
            }

            $packet = substr($packet, 0, -1);
            $packet .= " ],";
        }

        # This updates multiple checkboxes with the same name
        # Convert: $hash[key] = array( key1 => val1, key2 = val2 )
        # To:      key : { key1 : val1, key2 : val2 },
        elseif ( $this->_is_hash($val) ) {
            $packet .= "\"$key\": { ";
            foreach ( array_keys($val) as $key1 ) {
                if (!isset($val[$key1])) {
                    $val[$key1] = "";
                }

                $val[$key1] = $this->_escape_javascript( $val[$key1] );
                $packet .= "\"$key1\": \"$val[$key1]\",";
            }

            $packet = substr($packet, 0, -1);
            $packet .= "},";
        }
        else {
            error_log("I'm not sure what to do with the data structure you sent!");
        }

    }

    $packet = substr($packet, 0, -1);
    $packet .= "}";

    return $packet;

}

function _add_tags($code) {
    return "\r <OT><body onLoad=\"parent.OpenThought.ResponseComplete(self)\"></body><script>${code}</script><OT> \r";
}

function _escape_javascript($code) {

    if (!isset($code)) {
        return;
    }

    $code = preg_replace('/[\\\]/', '\\\\', $code);
    $code = preg_replace("/\n/", "\\n", $code);
    $code = preg_replace("/\r/", "\\r", $code);
    $code = preg_replace("/\t/", "\\t", $code);
    $code = preg_replace("/\"/", "\\\"", $code);
    $code = preg_replace('/([\x00-\x1F])/e', "sprintf('\\%03o', ord('\\1'))", $code);

    return $code;
}

function _is_hash($array) {
    #return is_array( $var ) && !is_numeric( implode( array_keys( $var ) ) );
    if (!is_array($array) || empty($array))
        return false;

    $keys = array_keys($array);
    return array_keys($keys) !== $keys;
}

function _is_array($array) {
    #return is_array( $var ) && is_numeric( implode( array_keys( $var ) ) );
    if (!is_array($array) || empty($array))
        return false;

    $keys = array_keys($array);
    return array_keys($keys) === $keys;
}

} # Don't bother me, I match with the class definition


?>
