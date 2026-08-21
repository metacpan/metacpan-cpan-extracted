#!/usr/bin/env perl

# Minimum Requirements:
#   PAGI::FastAPI v1.2.3
#   PAGI::FastAPI::Security v0.0.6
#
# API Gateway
#   pagi-server api_gateway --port 3000
#
# User Microservice
#   pagi-server user_microservice --port 3001
#
# Order Microservice
#   pagi-server order_microservice --port 3002
#
# Access API Gateway Dashboard
#   http://localhost:3000

use v5.36;
use JSON::PP;
use Future::HTTP;
use PAGI::FastAPI;
use Future::AsyncAwait;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Security::HTTPBearer;

my $SECRET_TOKEN = 'secret-token-123';

my $app = PAGI::FastAPI->new(
    title   => "API Gateway Dashboard",
    version => "1.0.0"
);

my $html_content = do { local $/; <DATA> };

# 1. Bearer Token Extractor
my $bearer = PAGI::FastAPI::Security::HTTPBearer->new(realm => 'APIGateway');

# 2. Token Validator Dependency
my $auth_check = async sub ($c) {
    my $token = $c->stash->{authToken} // '';
    unless (constant_time_eq($token, $SECRET_TOKEN)) {
        $c->set_header($bearer->challenge_header(error => 'invalid_token'));
        $c->status(401);
        return { message => 'Unauthorised Access' };
    }
    return 1;
};

# 3. Async HTTP Client Dependency
my $get_http = async sub ($c) {
    return Future::HTTP->new;
};

# 4. Service Endpoints Config Dependency
my $get_config = async sub ($c) {
    return {
        user_service_url  => 'http://127.0.0.1:3001',
        order_service_url => 'http://127.0.0.1:3002',
    };
};

$app->get('/', handler => async sub ($c) {
    return $c->html($html_content);
});

$app->get('/api/v1/dashboard/{id}',
    dependencies => [
        $bearer->depends(key => 'authToken'),
        Depends($auth_check),
        Depends($get_http,   key => 'http_client'),
        Depends($get_config, key => 'config'),
    ],
    handler => async sub ($c) {
        # Retrieve injected dependencies from stash
        my $http    = $c->stash->{http_client};
        my $config  = $c->stash->{config};
        my $user_id = $c->param('id') // 1;

        # Concurrent, non-blocking HTTP requests
        my $user_f  = $http->http_get("$config->{user_service_url}/users/$user_id");
        my $order_f = $http->http_get("$config->{order_service_url}/orders/user/$user_id");

        # Await both futures concurrently
        await Future->wait_all($user_f, $order_f);

        my $user_body  = eval { ($user_f->get)[0]        } // '{}';
        my $order_body = eval { ($order_f->get)[0]       } // '{}';

        my $user_data  = eval { decode_json($user_body)  } // {};
        my $order_data = eval { decode_json($order_body) } // {};

        return {
            user   => $user_data->{data}    // undef,
            orders => $order_data->{orders} // [],
        };
    }
);

$app->to_app;

sub constant_time_eq ($a, $b) {
    return 0 unless length($a) == length($b);

    # Unpack strings into real byte arrays
    my @a_bytes = unpack('C*', $a);
    my @b_bytes = unpack('C*', $b);

    my $diff = 0;

    for (my $i = 0; $i < @a_bytes; $i++) {
        $diff |= $a_bytes[$i] ^ $b_bytes[$i];
    }

    return $diff == 0;
}

__DATA__
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Microservice Dashboard</title>
    <style>
        body  { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f6f8; }
        .container { max-width: 600px; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input[type="text"] { width: 100%; padding: 8px; box-sizing: border-box; }
        button { padding: 10px 15px; background-color: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
        .card  { border: 1px solid #ddd; padding: 15px; border-radius: 4px; margin-top: 15px; }
        .error { color: red; margin-top: 15px; }
    </style>
</head>
<body>
<div class="container">
    <h2>API Gateway Dashboard</h2>
    <div class="form-group">
        <label for="userId">User ID:</label>
        <input type="text" id="userId" value="1">
    </div>
    <div class="form-group">
        <label for="authToken">Bearer Token:</label>
        <input type="text" id="authToken" value="secret-token-123">
    </div>
    <button onclick="fetchDashboard()">Fetch User Data</button>
    <div id="error" class="error"></div>
    <div id="result" style="display: none;">
        <div class="card">
            <h3>User Profile</h3>
            <p><strong>ID:</strong>
                <span id="prof-id"></span>
            </p>
            <p><strong>Name:</strong>
                <span id="prof-name"></span>
            </p>
            <p><strong>Role/Email:</strong>
                <span id="prof-detail"></span>
            </p>
        </div>
        <div class="card">
            <h3>Orders</h3>
            <ul id="orders-list"></ul>
        </div>
    </div>
</div>
<script>
async function fetchDashboard() {
    const userId            = document.getElementById('userId').value;
    const token             = document.getElementById('authToken').value;
    const errorDiv          = document.getElementById('error');
    const resultDiv         = document.getElementById('result');
    errorDiv.innerText      = '';
    resultDiv.style.display = 'none';

    try {
        const response = await fetch(`/api/v1/dashboard/${userId}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || `HTTP ${response.status}`);

        const user   = data.user   || {};
        const orders = data.orders || [];

        document.getElementById('prof-id').innerText = user.id       || 'N/A';
        document.getElementById('prof-name').innerText = user.name   || 'N/A';
        document.getElementById('prof-detail').innerText = user.role || user.email || 'N/A';

        const ordersList = document.getElementById('orders-list');
        ordersList.innerHTML = orders.length ? '' : '<li>No orders found.</li>';
        orders.forEach(o => {
            const li     = document.createElement('li');
            li.innerText = `${o.item} - $${o.price}`;
            ordersList.appendChild(li);
        });
        resultDiv.style.display = 'block';
    }
    catch (err) {
        errorDiv.innerText = `Error: ${err.message}`;
    }
}
</script>
</body>
</html>
