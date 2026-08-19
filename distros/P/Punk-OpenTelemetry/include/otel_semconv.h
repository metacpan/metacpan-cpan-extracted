/* otel_semconv.h - the semantic conventions, pinned.
 *
 * Attribute names are an interface. Dashboards, alerts and saved queries are
 * built on them, so changing one silently is an outage in somebody's
 * observability rather than a rename. They are therefore all in this file,
 * with the convention VERSION beside them, so "which conventions does this
 * speak" has an answer that cannot drift from the code.
 *
 * The HTTP conventions moved recently - http.method became
 * http.request.method, http.status_code became http.response.status_code -
 * and an application whose dashboards were built on one naming does not want
 * the other arriving because it upgraded. Hence the pin.
 *
 * CARDINALITY IS THE THEME. Every attribute here is either bounded by
 * construction or deliberately omitted. An unbounded attribute does not fail
 * loudly; it makes a backend slow and then expensive, and the bill arrives a
 * month after the deploy that caused it.
 */

#ifndef OTEL_SEMCONV_H
#define OTEL_SEMCONV_H

/* The convention version these names come from. Emitted as schema_url, so a
 * consumer can tell which vocabulary it is being handed. */
#define OTEL_SCHEMA_URL "https://opentelemetry.io/schemas/1.30.0"

/* ---- HTTP server -------------------------------------------------------- */
#define SC_HTTP_METHOD          "http.request.method"
#define SC_HTTP_METHOD_ORIGINAL "http.request.method_original"
#define SC_HTTP_ROUTE           "http.route"
#define SC_HTTP_STATUS          "http.response.status_code"
#define SC_URL_PATH             "url.path"
#define SC_URL_SCHEME           "url.scheme"
#define SC_URL_QUERY            "url.query"
#define SC_SERVER_ADDRESS       "server.address"
#define SC_SERVER_PORT          "server.port"
#define SC_CLIENT_ADDRESS       "client.address"
#define SC_USER_AGENT           "user_agent.original"
#define SC_NETWORK_PROTOCOL     "network.protocol.version"
#define SC_ERROR_TYPE           "error.type"

/* ---- HTTP client -------------------------------------------------------- */
#define SC_URL_FULL             "url.full"

/* ---- database ----------------------------------------------------------- */
#define SC_DB_SYSTEM            "db.system.name"
#define SC_DB_NAMESPACE         "db.namespace"
#define SC_DB_OPERATION         "db.operation.name"
#define SC_DB_QUERY_TEXT        "db.query.text"
#define SC_DB_COLLECTION        "db.collection.name"

/* ---- messaging ---------------------------------------------------------- */
#define SC_MSG_SYSTEM           "messaging.system"
#define SC_MSG_DESTINATION      "messaging.destination.name"
#define SC_MSG_OPERATION        "messaging.operation.type"
#define SC_MSG_MESSAGE_ID       "messaging.message.id"

/* ---- rpc / graphql ------------------------------------------------------ */
#define SC_GRAPHQL_OPERATION    "graphql.operation.name"
#define SC_GRAPHQL_TYPE         "graphql.operation.type"

/* The HTTP methods the conventions know.
 *
 * ANYTHING ELSE BECOMES "_OTHER", with the raw value in
 * http.request.method_original. The method is client-controlled and otherwise
 * unbounded - a scanner sending a thousand invented verbs would otherwise
 * create a thousand values of a metric dimension - and this attribute lands
 * in exactly such a dimension in the metrics phase. Normalising here means
 * nobody has to remember to do it there. */
static const char *const SC_KNOWN_METHODS[] = {
    "CONNECT", "DELETE", "GET", "HEAD", "OPTIONS",
    "PATCH", "POST", "PUT", "TRACE", NULL
};

/* Returns the canonical method, or NULL when it is not a known one - in which
 * case the caller emits "_OTHER" and keeps the original separately. */
static const char *otel_sc_method(const char *m, STRLEN len) {
    int i;
    if (!m || !len || len > 16) return NULL;
    for (i = 0; SC_KNOWN_METHODS[i]; i++) {
        if (strlen(SC_KNOWN_METHODS[i]) == len
            && memEQ(m, SC_KNOWN_METHODS[i], len))
            return SC_KNOWN_METHODS[i];
    }
    return NULL;
}

/* The span status implied by an HTTP status, for a SERVER span.
 *
 * 4xx is NOT an error on the server side. A 404 or a 401 is the server
 * working correctly and saying no; marking those as errors makes the error
 * rate a measure of how many people mistyped a URL, which is a graph nobody
 * can act on. 5xx is an error. Everything else is left UNSET, because an
 * instrumentation layer with no opinion must not claim one. */
static int otel_sc_server_status(IV http_status) {
    if (http_status >= 500) return OTEL_STATUS_ERROR;
    return OTEL_STATUS_UNSET;
}

/* For a CLIENT span the rule differs, and deliberately: a 4xx the client
 * received IS a failure of the call the client made. */
static int otel_sc_client_status(IV http_status) {
    if (http_status >= 400) return OTEL_STATUS_ERROR;
    return OTEL_STATUS_UNSET;
}

/* The leading keyword of a statement, uppercased, as db.operation.name -
 * SELECT, INSERT, UPDATE. Bounded to a short buffer, so a pathological
 * statement cannot make this allocate. Returns 0 when there is no sane
 * keyword to report. */
static int otel_sc_db_operation(const char *sql, STRLEN len, char *out,
                                STRLEN cap) {
    STRLEN i = 0, o = 0;
    if (!sql || !len || cap < 2) return 0;
    while (i < len && (sql[i] == ' ' || sql[i] == '\t' || sql[i] == '\n'
                       || sql[i] == '\r' || sql[i] == '(')) i++;
    while (i < len && o + 1 < cap) {
        char c = sql[i];
        if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
        if (!(c >= 'A' && c <= 'Z')) break;
        out[o++] = c;
        i++;
    }
    out[o] = '\0';
    return o > 0;
}

#endif /* OTEL_SEMCONV_H */
