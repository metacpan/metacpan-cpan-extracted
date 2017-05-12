var TapirClient;

dojo.provide('lib.TapirClient');

dojo.declare('Tapir', null, {
    // Definable by the user

    callUrl: null,
    cometdUrl: null,
    sessionId: null,

    onPendingSuccess: function () { },
    onPendingError: function () { },
    onPendingStatusMessage: function () { },

    // Common variables

    lastValidateError: null,
    thriftInternalTypes: {
        i16: 1,
        i32: 1,
        i64: 1,
        bool: 1,
        binary: 1,
        void: 1,
        string: 1,
        map: 1,
        double: 1,
        byte: 1,
        set: 1,
        list: 1
    },

    pendingRequests: {},

    services: [],

    // Methods

    namedTypeObject: function (param) {
        var name, obj;

        if (param === null) {
            throw "namedTypeObject called with null";
        }

        if (typeof param === 'string') {
            name = param;
        }
        else {
            name = param.type;
        }

        if (this.thriftInternalTypes[ name ]) {
            if (! Tapir.Type[name]) {
                throw "Unexpected: No Tapir.Type." + name + " class found";
            }
            obj = new Tapir.Type[name] (param);
        }
        else if (name.match(/\./)) {
            eval ('obj = new ' + name + '()');
        }
        else {
            if (! Tapir[name]) {
                throw "No Tapir." + name + " class found";
            }
            obj = new Tapir[name] (param);
        }
        return obj;
    },

    service: function (name) {
        return this.namedTypeObject(name);
    },

    pollPendingResults: function (request) {
        var self = this,
            wrappedOnSuccess = request.onSuccess,
            i, details, id, reconstructedRequest,
            pendingIds, key;

        if (wrappedOnSuccess) {
            request.onSuccess = function (request, result) {
                for (i = 0; i < result.length; i++) {
                    details = result[i];

                    id = details.id;

                    if (self.pendingRequests[id]) {
                        delete self.pendingRequests[id];
                    }

                    console.info(self.pendingRequests);
                    console.info("Should have deleted pending request " + id);

                    reconstructedRequest = {
                        service: details.request.serviceName,
                        method:  details.request.methodName,
                        params:  dojo.fromJson(details.request.paramsJSON),
                        id:      id,
                        pending: false
                    };

                    if (details.success) {
                        wrappedOnSuccess(reconstructedRequest, dojo.fromJson(details.resultJSON));
                    }
                    else if (request.onError) {
                        request.onError(reconstructedRequest, dojo.fromJson(details.resultJSON));
                    }
                }
            };
        }
        pendingIds = [];
        for (key in this.pendingRequests) {
            if (typeof this.pendingRequests[key] !== 'function') {
                pendingIds.push(key);
            }
        }
        dojo.mixin(request, {
            service: 'CP',
            method: 'getPendingResults',
            params: {
                ids: pendingIds
            }
        });
        this.sendRequests([request]);
    },

    checkValidateSpec: function (spec, value) {
        var match;
        if (spec.type === 'range') {
            if (spec.low  !== null && value * 1 < spec.low * 1) {
                return TapirClient.validateError("Too low");
            }
            if (spec.high !== null && value * 1 > spec.high * 1) {
                return TapirClient.validateError("Too high");
            }
        }
        else if (spec.type === 'length') {
            if (spec.low  !== null && value.length < spec.low * 1) {
                return TapirClient.validateError("Too short");
            }
            if (spec.high !== null && value.length > spec.high * 1) {
                return TapirClient.validateError("Too long");
            }
        }
        else if (spec.type === 'regex' && (match = /^\/(.+)\/$/.exec(spec.pattern))) {
            if (! new RegExp (match[1]).test(value)) {
                return TapirClient.validateError("Doesn't follow RegExp form");
            }
        }
        return true;
    },

    validateError: function (error) {
        //console.error(error);
        this.lastValidateError = error;
        return false;
    },

    sendRequests: function (requests) {
        var self = this, request;

        request = {
            url: TapirClient.callUrl,
            handleAs: 'json',
            load: function (result) { self.sendRequests_load(requests, result); },
            error: function (error) { self.sendRequests_error(requests, error); },
            headers: {
                'Content-Type': 'application/json'
            },
            postData: dojo.toJson(requests)
        };

        if (self.sessionId) {
            request.headers['Tapir-Session-ID'] = self.sessionId;
        }

        dojo.xhrPost(request);
        //console.info("Posted request to " + TapirClient.callUrl);
    },

    /*
        The response from a post to '/request' is going to be one of the following:

        - { error: ... }
          The request wasn't properly formed.  JSON decode error, invalid session id, etc.
        - [ { }, { } ]
          An array the same length as the requests, with each index corresponding to a request.
          A single response will look like one of the following:
          - { error: ... }
            The request had an error (invalid args, missing session id for call type, etc)
          - { result: ... }
            The synchronous request completed with the following result.  Is the return value of the method call.
          - { id: ... }
            The asynchronous request is pending, and has this id (valid only for this session)
    */

    sendRequests_load: function (requests, response) {
        if (response instanceof Object && response.error) {
            // Treat this the same as a transport error
            return this.sendRequests_error(requests, response.error);
        }

        var i, request;

        for (i = 0; i < requests.length; i++) {
            request = requests[i];

            if (! response[i]) {
                response[i] = { error: "No response found" };
            }

            // If 'id' is present, it's an async method
            if (response[i].id) {
                request.pending = true;
                request.id = response[i].id;
                this.pendingRequests[ response[i].id ] = request;
            }

            try {
                // Call the user provided callback
                if (response[i].error) {
                    if (request.onError) {
                        request.onError(request, response[i].error);
                    }
                }
                else if (request.onSuccess) {
                    request.onSuccess(request, response[i].result);
                }
            }
            catch (ex) {
                console.error("TapirClient: sendRequests user callback failed: ", request, response[i], ex);
            }
        }
    },

    sendRequests_error: function (requests, error) {
        var i, request;
        for (i = 0; i < requests.length; i++) {
            request = requests[i];
            if (request.onError) {
                try {
                    request.onError(request, error);
                }
                catch (ex) {
                    console.error("sendRequests error callback failed: ", request, error, ex);
                }
            }
            else {
                console.error("TapirClient: sendRequests failed " + request.method + '; ' + error);
            }
        }
    },

    bayeuxConnect: function () {
        dojo.require("dojox.cometd");
        dojox.cometd.init(this.cometdUrl);

        var setupSubscribe = true, lastClientId, unsubscribeFirst = false;

        this.dojoSubscribeHandle = dojo.subscribe('/cometd/meta', dojo.hitch(this, function (message) {
            // Perform the cometd subscribe call only upon new connections
            // Since the connection may be interrupted, and since POE::Component::Server::Bayeux will ask a client
            // to rehandshake if it believes there's already a long poll being performed by another thread,
            // the cometd will get a new clientId, so in this case it needs to reestablish the subscribe.
            if (message.action === 'connect' && message.successful === true && message.state === 'connected') {
                if (lastClientId === undefined) {
                    lastClientId = message.response.clientId;
                }
                else if (lastClientId !== message.response.clientId) {
                    setupSubscribe = true;
                    lastClientId = message.response.clientId;
                }

                if (setupSubscribe === false) {
                    return;
                }
            }
            else {
                return;
            }

            setupSubscribe = false;
            dojox.cometd.startBatch();

            if (unsubscribeFirst) {
                dojox.cometd.unsubscribe("/private/" + this.sessionId);
            }
            unsubscribeFirst = true;

            dojox.cometd.subscribe("/private/" + this.sessionId, function (message) {
                var self = TapirClient, ackIds = [], id, details;
                if (message.data.action === 'requests_completed') {
                    // Acknowledge the requests
                    for (id in message.data.requests) {
                        if (typeof message.data.requests[id] !== 'function') {
                            ackIds.push(id);
                        }
                    }
                    dojox.cometd.publish("/private/" + self.sessionId, {
                        action: 'requests_acknowledged',
                        ids: ackIds
                    });

                    for (id in message.data.requests) {
                        if (typeof message.data.requests[id] !== 'function') {
                            details = message.data.requests[id];
                            details.request.pending = false;
                            if (self.pendingRequests[id]) {
                                delete self.pendingRequests[id];
                            }
                            if (details.success) {
                                self.onPendingSuccess(details.request, details.result);
                            }
                            else {
                                self.onPendingError(details.request, details.error);
                            }
                        }
                    }
                }
                else if (message.data.action === 'request_interim_status') {
                    id = message.data.requestId;
                    if (! self.pendingRequests[id]) {
                        return;
                    }
                    self.onPendingStatusMessage( self.pendingRequests[id], message.data.status );
                }
            });

            var pendingRequestIds = [], id;
            for (id in this.pendingRequests) {
                if (typeof this.pendingRequests[id] !== 'function') {
                    pendingRequestIds.push(id);
                }
            }

            dojox.cometd.publish("/private/" + this.sessionId, {
                action: 'requests_status',
                ids: pendingRequestIds
            });

            dojox.cometd.endBatch();
        }));
    },

    bayeuxDisconnect: function () {
        if (this.dojoSubscribeHandle !== undefined) {
            dojo.unsubscribe(this.dojoSubscribeHandle);
            delete this.dojoSubscribeHandle;
        }
        dojox.cometd.disconnect();
    }
});

TapirClient = new Tapir ();

// Generic, static class definitions

dojo.declare('Tapir.Type', null, {
    validate: function (value) {
        throw "validate() called on non-overloaded class";
    },
    baseType: function () {
        var cur = this;
        while (cur.referencedTypeObject) {
            cur = cur.referencedTypeObject();
        }
        return cur;
    },
    classChain: function (chain) {
        if (! chain) {
            chain = [];
        }
        if (this.declaredClass) {
            chain.push(this.declaredClass);
        }
        if (this.constructor && this.constructor.superclass && this.constructor.superclass.classChain) {
            this.constructor.superclass.classChain(chain);
        }
        return chain;
    },
    classChainHash: function () {
        var chain = this.classChain(),
            hash = {}, i;
        for (i = 0; i < chain.length; i++) {
            hash[ chain[i] ] = 1;
        }
        return hash;
    }
});

dojo.declare('Tapir.Type.bool', Tapir.Type, {
    validate: function (value) {
        if (null === value) {
            return TapirClient.validateError("Bool cannot be null");
        }
        if (value === true || value === false) {
            return true;
        }
        return TapirClient.validateError("Bool is only 'true' or 'false'");
    }
});

dojo.declare('Tapir.Type.string', Tapir.Type, {
    validate: function (value) {
        if (null === value) {
            return TapirClient.validateError("String cannot be null");
        }
        return true;
    }
});

dojo.declare('Tapir.Type.Number', Tapir.Type, {
    validate: function (value) {
        if (! /^-?\d+$/.test(value)) {
            return TapirClient.validateError("Not a number");
        }
        if (null === value) {
            return TapirClient.validateError("Number cannot be null");
        }
        if (this._max_value && Math.abs(value) > this._max_value) {
            return TapirClient.validateError("Number is too large");
        }
        return true;
    }
});
dojo.declare('Tapir.Type.byte', Tapir.Type.Number, {
    _max_value: Math.pow(2, 7)
});
dojo.declare('Tapir.Type.i16', Tapir.Type.Number, {
    _max_value: Math.pow(2, 15)
});
dojo.declare('Tapir.Type.i32', Tapir.Type.Number, {
    _max_value: Math.pow(2, 31)
});
dojo.declare('Tapir.Type.i64', Tapir.Type.Number, {
    _max_value: Math.pow(2, 63)
});
dojo.declare('Tapir.Type.double', Tapir.Type.Number, {
});

dojo.declare('Tapir.Type.Custom', Tapir.Type, {
    type: null,
    validateSpec: [],

    referencedTypeObject: function () {
        return TapirClient.namedTypeObject(this.type);
    },

    validate: function (value) {
        var type = this.referencedTypeObject(), i, allowUTF8 = false;
        if (! type.validate(value)) {
            return false;
        }

        // Use validateSpec to test business logic
        for (i = 0; i < this.validateSpec.length; i++) {
            if (this.validateSpec[i].type === 'utf8') {
                allowUTF8 = true;
            }
            if (! TapirClient.checkValidateSpec(this.validateSpec[i], value)) {
                return false;
            }
        }

        if (! allowUTF8 &&
            type.classChainHash()['Tapir.Type.string'] &&
            /[^\u0000-\u007f]/.test(value)) {
            return TapirClient.validateError("String cannot contain Unicode characters");
        }

        return true;
    }
});

dojo.declare('Tapir.Type.Container', Tapir.Type, {
    constructor: function (args) {
        dojo.mixin(this, args);
    },
    valType: null,
    validate: function (value) {
        var keyType, valType = TapirClient.namedTypeObject(this.valType), i;

        if (this.keyType) {
            keyType = TapirClient.namedTypeObject(this.keyType);
        }

        for (i in value) {
            if (typeof value[i] !== 'function') {
                if (keyType !== undefined && ! keyType.validate(i)) {
                    return false;
                }
                if (! valType.validate(value[i])) {
                    return false;
                }
                //console.debug("Checking '" + value[i] + "' against type " + this.valType);
            }
        }
        return true;
    }
});

dojo.declare('Tapir.Type.list', Tapir.Type.Container, {
});
dojo.declare('Tapir.Type.set', Tapir.Type.Container, {
});
dojo.declare('Tapir.Type.map', Tapir.Type.Container, {
    keyType: null
});

dojo.declare('Tapir.Type.Field', Tapir.Type, {
    validateSpec: [],

    constructor: function (args) {
        dojo.mixin(this, args);
    },

    Type: function () {
        return TapirClient.namedTypeObject(this.type);
    },

    validate: function (value) {
        var i, type = this.Type(), allowUTF8 = false,
            typeClassChain = type.classChainHash(),
            validateSpec = dojo.clone(this.validateSpec),
            baseType = type;

        if (value === null || (typeof value === 'string' && value.length === 0)) {
            if (this.optional) {
                return true;
            }
            return TapirClient.validateError("Missing value for required field '" + this.name + "'");
        }

        if (typeClassChain['Tapir.Type.Custom']) {
            // Repoint the base type to the referenced type of the custom type
            baseType = type.referencedTypeObject();
            // Copy in the validate spec items from the custom type declaration (TODO: support more than one level of custom types)
            dojo.forEach(type.validateSpec, function (item) {
                validateSpec.push(item);
            });
            // Extend the parent class hash with the parent class(es) of the referenced type (usually a base type like string)
            dojo.mixin(typeClassChain, baseType.classChainHash());
        }

        // Check base-type validation first
        if (! baseType.validate(value)) {
            return false;
        }

        // Check field-specific validation specs
        for (i = 0; i < validateSpec.length; i++) {
            if (validateSpec[i].type === 'utf8') {
                allowUTF8 = true;
            }
            if (! TapirClient.checkValidateSpec(validateSpec[i], value)) {
                return false;
            }
        }

        if (! allowUTF8 &&
            typeClassChain['Tapir.Type.string'] &&
            /[^\u0000-\u007f]/.test(value)) {
            return TapirClient.validateError("String cannot contain Unicode characters");
        }

        return true;
    }
});

dojo.declare('Tapir.Type.Struct', Tapir.Type, {
    fieldSpec: [],

    constructor: function (value) {
        this.value = value;
    },

    fields: function () {
        return dojo.map(this.fieldSpec, function (item) {
            return new Tapir.Type.Field(item);
        });
    },

    // Returns field spec given name or index
    field: function (name_or_index) {
        var i, fld;

        if (typeof name_or_index === 'number') {
            fld = this.fieldSpec[name_or_index];
            if (! fld) {
                throw "No such field numbered " + name_or_index;
            }
        }
        else {
            for (i = 0; i < this.fieldSpec.length; i++) {
                if (this.fieldSpec[i].name === name_or_index) {
                    fld = this.fieldSpec[i];
                }
            }
            if (! fld) {
                throw "No such field named '" + name_or_index + "'";
            }
        }

        return new Tapir.Type.Field(fld);
    },

    // Returns boolean; params are complete and valid for a call
    validate: function (original) {
        var params = dojo.clone(original),
            i, key, val, extraKeys = [], fields, field;

        // If no argument is passed, use the constructor value
        if (original === undefined && this.value !== null) {
            original = this.value;
        }

        fields = this.fields();
        for (i = 0; i < fields.length; i++) {
            field = fields[i];
            val = params[field.name];
            delete params[field.name];

            if (! field.validate(val)) {
                return false;
            }
        }

        // Check for extra, unreferenced keys
        extraKeys = [];
        for (key in params) {
            if (typeof params[key] !== 'function') {
                extraKeys.push(key);
            }
        }
        if (extraKeys.length) {
            TapirClient.validateError(
                "Keys " +
                dojo.map(extraKeys, function (val) { return '"' + val + '"'; }).join(', ') +
                " were not part of the structure field specification"
            );
            return false;
        }

        return true;
    }
});

dojo.declare('Tapir.Type.Exception', Tapir.Type.Struct, {
});

dojo.declare('Tapir.Type.Enum', Tapir.Type, {
    values: {},
    validate: function (value) {
        if (this.values[value] !== null) {
            return true;
        }
        return false;
    }
});

dojo.declare('Tapir.Service', null, {
    // Attributes defined in subclasses
    baseName: null,
    methods: [],

    // Common methods

    constructor: function (args) {
        dojo.mixin(this, args);
    },

    method: function (name) {
        var i, obj;
        for (i = 0; i < this.methods.length; i++) {
            if (this.methods[i] !== name) {
                continue;
            }
            eval ('obj = new ' + this.baseName + '.' + name + '()');
            return obj;
        }
        console.error("Method '" + name + "' not found in service");
        return null;
    }
});

dojo.declare('Tapir.Method', Tapir.Type.Struct, {
    // Attributes defined in subclasses
    // fieldSpec: [], // part of the Struct parent
    name: null,
    serviceName: null,
    spec: {},

    // Common methods

    Service: function () {
        return this.namedTypeObject(this.serviceName);
    },

    call: function (request) {
        var self = this;

        request.service = self.serviceName;
        request.method  = self.name;

        TapirClient.sendRequests([ request ]);
    }

});
