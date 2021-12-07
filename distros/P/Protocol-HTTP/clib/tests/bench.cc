#include "test.h"
#include <unordered_map>
#include <catch2/benchmark/catch_benchmark.hpp>

static string xcnt (string s, int cnt) {
    string ret;
    ret.reserve(s.length() * cnt);
    for (int i = 0; i < cnt; ++i) ret += s;
    return ret;
}

TEST_CASE("bench iequals", "[.bench]") {
    std::unordered_map<string,std::pair<string, string>> m = {
        {"short", {"Cookie","cookie"}},
        {"medium", {"Transfer-Encoding123", "transfer-encoding123"}},
        {"long", {xcnt("Transfer-Encoding123",50), xcnt("Transfer-Encoding123",50)}},
    };

    string_view s1 = m.at("short").first;
    string_view s2 = m.at("short").second;
    BENCHMARK("short") {
        return iequals(s1,s2);
    };

    string_view m1 = m.at("medium").first;
    string_view m2 = m.at("medium").second;
    BENCHMARK("medium") {
        return iequals(m1,m2);
    };

    string_view l1 = m.at("long").first;
    string_view l2 = m.at("long").second;
    BENCHMARK("long") {
        return iequals(l1,l2);
    };
}

TEST_CASE("bench request", "[.bench]") {
    RequestParser p;
    string buf =
        "POST http://alx3apps.appspot.com/jsonrpc_example/json_service/ HTTP/1.1\r\n"
        "Host: alx3apps.appspot.com\r\n"
        "Content-Length: 55\r\n"
        "\r\n"
        "{\"params\":[\"Howdy\",\"Python!\"],\"method\":\"concat\",\"id\":1}";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench request min", "[.bench]") {
    RequestParser p;
    string buf =
        "GET / HTTP/1.1\r\n"
        "Host: ya.ru\r\n"
        "\r\n";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench response min", "[.bench]") {
    RequestSP req = new Request();
    ResponseParser p;
    p.set_context_request(req);
    string buf =
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 0\r\n"
        "\r\n";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.set_context_request(req);
        p.parse(buf);
    };
}

TEST_CASE("bench request mid", "[.bench]") {
    RequestParser p;
    string buf =
        "GET /49652gatedesc.xml HTTP/1.0\r\n"
        "Host: 192.168.100.1:49652\r\n"
        "User-Agent: Go-http-client/1.1\r\n"
        "Accept-Encoding: gzip\r\n"
        "\r\n";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench response mid", "[.bench]") {
    RequestSP req = new Request();
    ResponseParser p;
    p.set_context_request(req);
    string buf =
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 0\r\n"
        "Host: 192.168.100.1:49652\r\n"
        "User-Agent: Go-http-client/1.1\r\n"
        "Accept-Encoding: gzip\r\n"
        "\r\n";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.set_context_request(req);
        p.parse(buf);
    };
}

TEST_CASE("bench request mid2", "[.bench]") {
    RequestParser p;
    string buf =
        "GET /49652gatedesc/dasfdsf/sdf.xml?ddsf=dsfdsf&adsfdsf=dafdsfds HTTP/1.0\r\n"
        "Host: 192.168.100.1:49652\r\n"
        "User-Agent: Go-http-client/1.1\r\n"
        "Accept-Encoding: gzip\r\n"
        "\r\n";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench body", "[.bench]") {
    RequestParser p;
    string buf =
        "POST http://alx3apps.appspot.com/jsonrpc_example/json_service/ HTTP/1.1\r\n"
        "Host: alx3apps.appspot.com\r\n"
        "Content-Length: 500\r\n"
        "\r\n"
        "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench request heavy headers", "[.bench]") {
    RequestParser p;
    string buf =
        "POST http://alx3apps.appspot.com/jsonrpc_example/json_service/ HTTP/1.1\r\n"
        "Host: alx3apps.appspot.com\r\n"
        "User-Agent: Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13\r\n"
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
        "Accept-Language: en-gb,en;q=0.5\r\n"
        "Accept-Encoding: gzip,deflate\r\n"
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n"
        "Keep-Alive: 115\r\n"
        "Connection: keep-alive\r\n"
        "Content-Type: application/json-rpc;charset=UTF-8\r\n"
        "X-Requested-With: XMLHttpRequest\r\n"
        "Referer: http://alx3apps.appspot.com/jsonrpc_example/\r\n"
        "Content-Length: 0\r\n"
        "Pragma: no-cache\r\n"
        "Cache-Control: no-cache\r\n"
        "\r\n"
        ;
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench heavy chunked", "[.bench]") {
    RequestParser p;
    string buf =
        "POST http://alx3apps.appspot.com/jsonrpc_example/json_service/ HTTP/1.1\r\n"
        "Host: alx3apps.appspot.com\r\n"
        "User-Agent: Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13\r\n"
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
        "Accept-Language: en-gb,en;q=0.5\r\n"
        "Accept-Encoding: gzip,deflate\r\n"
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n"
        "Keep-Alive: 115\r\n"
        "Connection: keep-alive\r\n"
        "Content-Type: application/json-rpc;charset=UTF-8\r\n"
        "X-Requested-With: XMLHttpRequest\r\n"
        "Referer: http://alx3apps.appspot.com/jsonrpc_example/\r\n"
        "Content-Length: 0\r\n"
        "Pragma: no-cache\r\n"
        "Transfer-Encoding: gzip\r\n"
        "\r\n"
        ;
    if (p.parse(buf).error) throw std::logic_error(p.parse(buf).error.message());
    //warn("%d", p.parse(buf).request->headers.size());

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench heavy cookies", "[.bench]") {
    RequestParser p;
    string buf =
        "GET / HTTP/1.1\r\n"
        "Content-Length: 0\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "Cookie: asfkldasfkljdskjfjkldsfkljdas=dasfkjdhjsfjdsafkj; asdfdasfdasfdasf=dasfdasfjkdashfds\r\n"
        "\r\n"
        ;
    if (p.parse(buf).error) throw p.parse(buf).error;

    BENCHMARK("") {
        p.parse(buf);
    };
}

TEST_CASE("bench response heavy headers", "[.bench]") {
    RequestSP req = new Request();
    ResponseParser p;
    p.set_context_request(req);
    string buf =
        "HTTP/1.1 200 OK\r\n"
        "Host: alx3apps.appspot.com\r\n"
        "User-Agent: Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13\r\n"
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
        "Accept-Language: en-gb,en;q=0.5\r\n"
        "Accept-Encoding: gzip,deflate\r\n"
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n"
        "Keep-Alive: 115\r\n"
        "Connection: keep-alive\r\n"
        "Content-Type: application/json-rpc;charset=UTF-8\r\n"
        "X-Requested-With: XMLHttpRequest\r\n"
        "Referer: http://alx3apps.appspot.com/jsonrpc_example/\r\n"
        "Content-Length: 0\r\n"
        "Pragma: no-cache\r\n"
        "Cache-Control: no-cache\r\n"
        "\r\n"
        ;
    if (p.parse(buf).error) throw p.parse(buf).error;
    p.eof();

    BENCHMARK("") {
        p.set_context_request(req);
        p.parse(buf);
        p.eof();
    };
}


TEST_CASE("bench request serialize mid", "[.bench]") {
    URISP uri = new URI("http://alx3apps.appspot.com");
    BENCHMARK("") {
        auto req = Request::Builder()
                .uri(uri)
                .headers(Headers()
                    .add("MyHeader", "my value")
                    .add("User-Agent", "Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13")
                    .add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n")
                    .add("Accept-Language", "my value"))
               .allow_compression(Compression::GZIP)
               .body("zzz")
               .build();
        return req->to_string();
    };
}

TEST_CASE("bench response serialize mid", "[.bench]") {
    auto req = Request::Builder()
            .headers(Headers()
                .add("MyHeader", "my value")
                .add("User-Agent", "Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13")
                .add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n")
                .add("Accept-Language", "my value"))
           .allow_compression(Compression::GZIP)
           .body("zzz")
           .build();

    BENCHMARK("") {
        auto res = Response::Builder()
                .headers(Headers()
                    .connection("keep-alive")
                    .add("MyHeader", "my value")
                    .add("MyHeader1", "my value1")
                    .add("MyHeader2", "my value2")
                )
                .cookie("c1", Response::Cookie("abcdef").domain("crazypanda.ru").max_age(1000).path("/").http_only(true))
                .cookie("c2", Response::Cookie("defjgl").domain("crazypanda.ru").max_age(1000).path("/").http_only(true).secure(true))
                .body("hello")
                .build();
        return res->to_string(req);
    };
}
