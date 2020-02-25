const UTIL = {
    alert ( text ) {
        alert( text );
    },

    async sleep ( timeout ) {
        return new Promise( ( resolve ) => setTimeout( resolve, timeout ) );
    },

    async waitForSelector ( selector, timeout, check_interval ) {
        if ( !timeout ) timeout = 10000;

        if ( !check_interval ) check_interval = 100;

        while ( 1 ) {
            const el = document.querySelector( selector );

            // found
            if ( el ) return el;

            if ( timeout <= 0 ) return;

            await UTIL.sleep( check_interval );

            timeout -= check_interval;
        }
    },
};

window.UTIL = UTIL;
// -----SOURCE FILTER LOG BEGIN-----
//
// +-------+---------------+------------------------------+--------------------------------------------------------------------------------+
// | Sev.  | Line:Col      | Rule                         | Description                                                                    |
// |=======+===============+==============================+================================================================================|
// | ERROR | 17:17         | no-constant-condition        | Unexpected constant condition.                                                 |
// +-------+---------------+------------------------------+--------------------------------------------------------------------------------+
//
// -----SOURCE FILTER LOG END-----
