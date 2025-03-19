#include "catch2/catch_test_macros.hpp"
#include "panda/protocol/http/Body.h"
#include "panda/protocol/http/Headers.h"
#include "panda/protocol/http/Message.h"
#include "panda/protocol/http/Request.h"
#include "panda/protocol/http/RequestParser.h"
#include "panda/protocol/http/Response.h"
#include "panda/protocol/http/ResponseParser.h"
#include "panda/protocol/http/compression/Compression.h"
#include "panda/uri/URI.h"
#include "test.h"
#include <iostream>

TEST_CASE("synopsys", "[.]") {
    using namespace panda::protocol::http;
    RequestSP request = Request::Builder()
        .method(Method::Get)
        .uri("http://crazypanda.ru/hello/world")
        .header("MyHeader", "my value")
        .header("MyAtherH", "val2")
        .cookie("coo1", "val2")
        .body("my body")
        .build();

    string req_str = request->to_string(); // => GET /hello/world HTTP/1.1| ...

    // server api - parse request
    // my ($state, $position, $error);
    RequestParser req_parser;
    auto result = req_parser.parse(req_str);
    if (result.state == State::done) {
        RequestSP request = result.request;
        std::cout << request->uri << "\n"
                  << request->body;

        string next_req = req_str.substr(result.position);
    }

    // server api - make response
    ResponseSP response = Response::Builder()
        .code(200)
        .header("Lang", "C++")
        .body("Lorem ipsum dolor")
        .build();

    string res_str = response->to_string(request);

    // client api - parse response
    ResponseParser res_parser;
    res_parser.set_context_request(request);
    auto response_result = res_parser.parse(res_str);
    if (response_result.state == State::done) {
        ResponseSP response = response_result.response;
        std::cout << response->code    // 200, 404, etc
                  << response->message // status message, e.g OK
                  << response->body;
    }
    // compression with chunks

    request = Request::Builder()
        .method(Method::Post)
        .uri("https://images.example.com/upload")
        .compress(compression::Compression::GZIP)
        .chunked()
        .build();

    std::cout << request->to_string(); // only http headers
    auto chunk = request->make_chunk("hello-world"); // outputs first chunk
    for (const string& s : chunk) {
        std::cout << s;
    }
    chunk = request->final_chunk(); // outputs final chunk
    for (const string& s : chunk) {
        std::cout << s;
    }

    // cookies jar (for user-agents aka HTTP-clients)
    CookieJar jar;
    jar.populate(*request); // before request sent
    jar.collect(*response, request->uri); // after response is received
}