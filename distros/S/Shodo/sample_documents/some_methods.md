## POST /

get_entries

### Request

```json
POST /

{
   "params" : {
      "limit" : 1,
      "category" : "technology"
   },
   "jsonrpc" : "2.0",
   "method" : "get_entries"
}

```

### Parameters

* `page` - Page number you want to get.
  * isa: **Int**
  * default: **1**
  * optional: **1**
* `limit` - Limitation numbers per page.
  * isa: **Int**
  * default: **20**
  * optional: **1**
* `category` - Category of articles.
  * isa: **Str**

### Response

```json
Status: 200

{
   "jsonrpc" : "2.0",
   "id" : 1,
   "result" : {
      "entries" : [
         {
            "body" : "This is an example.",
            "title" : "Hello"
         }
      ]
   }
}

```

---

